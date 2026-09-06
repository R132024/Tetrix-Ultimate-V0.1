/// Multijugador PvP (1v1) ultra eficiente.
///
/// Arquitectura:
///   • Firebase Realtime Database = SOLO servidor de señalización (signaling)
///     durante el emparejamiento. No transporta el gameplay.
///   • WebRTC DataChannel = gameplay directo P2P (celular ↔ celular).
///
/// Esto permite miles de usuarios simultáneos a costo casi cero, porque una vez
/// establecido el puente WebRTC, Firebase deja de usarse para esa partida.
///
/// IMPORTANTE: requiere configuración nativa de Firebase (google-services.json /
/// GoogleService-Info.plist) y permisos de WebRTC en Android/iOS. Ver
/// `lib/online/README_FIREBASE.md`.
library;

import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';

/// Estado de la conexión P2P, expuesto a la UI.
enum P2PStatus {
  idle,
  creating,
  waitingRival,
  joining,
  connecting,
  connected,
  closed,
  error,
}

/// Rol del jugador en la partida.
enum P2PRole { host, client }

/// Gestiona el ciclo de vida completo de una partida online 1v1.
///
/// Uso típico (Host):
///   final mgr = P2PGameManager();
///   final roomId = await mgr.crearPartida();
///   // comparte roomId por WhatsApp; cuando el cliente entra -> onConnected
///
/// Uso típico (Cliente):
///   await mgr.unirseAPartida(roomId);
class P2PGameManager {
  P2PGameManager({FirebaseDatabase? db})
      : _db = db ?? FirebaseDatabase.instance;

  final FirebaseDatabase _db;
  static const _uuid = Uuid();

  // ─── Configuración WebRTC (STUN público gratuito de Google) ───
  static const Map<String, dynamic> _rtcConfig = {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
        ],
      },
      // Para producción agrega aquí un servidor TURN (necesario cuando ambos
      // jugadores están detrás de NAT simétrico). Ej: Twilio, Metered, coturn.
    ],
  };

  static const Map<String, dynamic> _offerAnswerConstraints = {
    'mandatory': {},
    'optional': [],
  };

  // ─── Estado interno ───
  String? _roomId;
  P2PRole? _role;
  RTCPeerConnection? _pc;
  RTCDataChannel? _channel;

  final List<StreamSubscription> _subs = [];
  bool _disposed = false;
  bool _remoteDescSet = false;
  final List<RTCIceCandidate> _pendingRemoteCandidates = [];

  // ─── Notificadores reactivos para la UI ───
  final ValueNotifier<P2PStatus> status =
      ValueNotifier<P2PStatus>(P2PStatus.idle);
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  /// Callback de gameplay: se invoca con cada evento del rival recibido por el
  /// DataChannel (ya decodificado a Map). La UI/engine se suscribe aquí.
  void Function(Map<String, dynamic> event)? onGameEvent;

  /// Se invoca cuando el rival abandona o se cae la conexión.
  void Function()? onRivalLeft;

  /// Callback cuando el host cambia el modo de juego.
  void Function(String mode)? onModeReceived;

  /// Callback cuando el host inicia el juego.
  void Function()? onGameStart;

  String selectedMode = 'classic';

  String? get roomId => _roomId;
  P2PRole? get role => _role;
  bool get isConnected => status.value == P2PStatus.connected;

  DatabaseReference get _roomRef => _db.ref('salas_pvp/$_roomId');

  // ════════════════════════════════════════════════════════════════════
  //  FLUJO DEL HOST
  // ════════════════════════════════════════════════════════════════════

  /// Crea una sala, publica la oferta SDP y espera la respuesta del cliente.
  /// Devuelve el [roomId] generado (para compartir por WhatsApp).
  Future<String?> crearPartida() async {
    try {
      _role = P2PRole.host;
      _roomId = _uuid.v4().substring(0, 8); // ID corto y legible
      status.value = P2PStatus.creating;

      // 1) Nodo inicial de la sala en Firebase.
      await _roomRef.set({
        'estado': 'esperando_rival',
        'creado': ServerValue.timestamp,
      });
      // Si la app se cierra de golpe, limpiamos la sala automáticamente.
      _roomRef.onDisconnect().remove();

      // 2) PeerConnection + DataChannel (el host crea el canal).
      await _initPeerConnection();
      final channel = await _pc!.createDataChannel(
        'beattris',
        RTCDataChannelInit()..ordered = true,
      );
      _registrarDataChannel(channel);

      // 3) ICE candidates del host -> Firebase.
      _pc!.onIceCandidate = (candidate) {
        _roomRef.child('ice_candidates_host').push().set(candidate.toMap());
      };

      // 4) Oferta SDP (Offer) -> Firebase.
      final offer = await _pc!.createOffer(_offerAnswerConstraints);
      await _pc!.setLocalDescription(offer);
      await _roomRef.child('host_sdp').set({
        'type': offer.type,
        'sdp': offer.sdp,
      });

      status.value = P2PStatus.waitingRival;

      // 5) Escuchar la respuesta del cliente (Answer).
      _subs.add(
        _roomRef.child('client_sdp').onValue.listen((event) async {
          final data = event.snapshot.value;
          if (data == null || _remoteDescSet) return;
          final map = Map<String, dynamic>.from(data as Map);
          await _pc!.setRemoteDescription(
            RTCSessionDescription(map['sdp'] as String, map['type'] as String),
          );
          _remoteDescSet = true;
          await _flushPendingCandidates();
          await _roomRef.child('estado').set('jugando');
        }),
      );

      // 6) Escuchar ICE candidates del cliente.
      _subs.add(
        _roomRef.child('ice_candidates_client').onChildAdded.listen((event) {
          _addRemoteCandidate(event.snapshot.value);
        }),
      );

      return _roomId;
    } catch (e, st) {
      _fail('No se pudo crear la partida: $e', st);
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════════
  //  FLUJO DEL CLIENTE
  // ════════════════════════════════════════════════════════════════════

  /// Se une a una sala existente: lee la oferta del host, genera la respuesta
  /// (Answer) y la sube para cerrar el puente.
  Future<void> unirseAPartida(String roomId) async {
    try {
      _role = P2PRole.client;
      _roomId = roomId;
      status.value = P2PStatus.joining;

      // 0) Validar que la sala exista.
      final snap = await _roomRef.get();
      if (!snap.exists) {
        _fail('La sala no existe o ya expiró.');
        return;
      }

      await _initPeerConnection();

      // El cliente NO crea el canal; lo recibe.
      _pc!.onDataChannel = (channel) => _registrarDataChannel(channel);

      // ICE candidates del cliente -> Firebase.
      _pc!.onIceCandidate = (candidate) {
        _roomRef.child('ice_candidates_client').push().set(candidate.toMap());
      };

      // 1) Leer la oferta del host (con reintentos).
      DataSnapshot? offerSnap;
      for (int i = 0; i < 5; i++) {
        offerSnap = await _roomRef.child('host_sdp').get();
        if (offerSnap.exists) break;
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      if (offerSnap == null || !offerSnap.exists) {
        _fail('El anfitrión aún no publicó la oferta.');
        return;
      }
      final offerMap = Map<String, dynamic>.from(offerSnap.value as Map);
      await _pc!.setRemoteDescription(
        RTCSessionDescription(
          offerMap['sdp'] as String,
          offerMap['type'] as String,
        ),
      );
      _remoteDescSet = true;

      status.value = P2PStatus.connecting;

      // 2) Generar respuesta (Answer) y subirla.
      final answer = await _pc!.createAnswer(_offerAnswerConstraints);
      await _pc!.setLocalDescription(answer);
      await _roomRef.child('client_sdp').set({
        'type': answer.type,
        'sdp': answer.sdp,
      });

      // 3) Escuchar ICE candidates del host.
      _subs.add(
        _roomRef.child('ice_candidates_host').onChildAdded.listen((event) {
          _addRemoteCandidate(event.snapshot.value);
        }),
      );

      await _flushPendingCandidates();
    } catch (e, st) {
      _fail('No se pudo unir a la partida: $e', st);
    }
  }

  // ════════════════════════════════════════════════════════════════════
  //  CANAL DE DATOS EN TIEMPO REAL (RTCDataChannel)
  // ════════════════════════════════════════════════════════════════════

  void _registrarDataChannel(RTCDataChannel channel) {
    _channel = channel;

    channel.onDataChannelState = (state) {
      if (_disposed) return;
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        status.value = P2PStatus.connected;
      } else if (state == RTCDataChannelState.RTCDataChannelClosed) {
        if (status.value == P2PStatus.connected) {
          onRivalLeft?.call();
          status.value = P2PStatus.closed;
        }
      }
    };

    channel.onMessage = (RTCDataChannelMessage message) {
      if (_disposed || message.isBinary) return;
      try {
        final decoded = jsonDecode(message.text);
        if (decoded is Map<String, dynamic>) {
          final t = decoded['t'];
          if (t == 'mode') {
             selectedMode = decoded['mode'];
             onModeReceived?.call(selectedMode);
          } else if (t == 'start') {
             selectedMode = decoded['mode'];
             onModeReceived?.call(selectedMode);
             onGameStart?.call();
          } else {
             onGameEvent?.call(decoded);
          }
        }
      } catch (_) {
        // Mensaje malformado: se ignora para no tumbar la partida.
      }
    };
  }

  /// Envía un evento genérico de juego al rival.
  void _send(Map<String, dynamic> event) {
    final ch = _channel;
    if (ch == null) return;
    try {
      ch.send(RTCDataChannelMessage(jsonEncode(event)));
    } catch (e) {
      debugPrint('P2P send error: $e');
    }
  }

  /// Envía líneas de basura al rival (ataque clásico de Tetris PvP).
  void enviarLineaBasura(int lineas) =>
      _send({'t': 'garbage', 'lines': lineas});

  void enviarSpeedUp() => _send({'t': 'speedup'});

  void enviarModo(String mode) {
    selectedMode = mode;
    _send({'t': 'mode', 'mode': mode});
  }

  void iniciarJuego(String mode) {
    selectedMode = mode;
    _send({'t': 'start', 'mode': mode});
    onGameStart?.call();
  }

  /// Notifica que tu tablero cambió (para mini-vista del rival, opcional).
  void enviarEstadoTablero(List<int> boardSnapshot, int score) =>
      _send({'t': 'board', 'cells': boardSnapshot, 'score': score});

  /// Notifica game over (perdiste -> el rival gana).
  void enviarGameOver() => _send({'t': 'gameover'});

  // ════════════════════════════════════════════════════════════════════
  //  WebRTC helpers
  // ════════════════════════════════════════════════════════════════════

  Future<void> _initPeerConnection() async {
    _pc = await createPeerConnection(_rtcConfig);

    _pc!.onConnectionState = (state) {
      if (_disposed) return;
      if (state ==
              RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        if (status.value == P2PStatus.connected) {
          onRivalLeft?.call();
        }
        status.value = P2PStatus.closed;
      }
    };
  }

  void _addRemoteCandidate(dynamic raw) {
    if (raw == null) return;
    final map = Map<String, dynamic>.from(raw as Map);
    final candidate = RTCIceCandidate(
      map['candidate'] as String?,
      map['sdpMid'] as String?,
      (map['sdpMLineIndex'] as num?)?.toInt(),
    );
    if (_remoteDescSet) {
      _pc?.addCandidate(candidate);
    } else {
      // No se puede añadir un candidate antes de setRemoteDescription.
      _pendingRemoteCandidates.add(candidate);
    }
  }

  Future<void> _flushPendingCandidates() async {
    for (final c in _pendingRemoteCandidates) {
      await _pc?.addCandidate(c);
    }
    _pendingRemoteCandidates.clear();
  }

  void _fail(String msg, [StackTrace? st]) {
    debugPrint('P2PGameManager ERROR: $msg\n$st');
    errorMessage.value = msg;
    status.value = P2PStatus.error;
  }

  // ════════════════════════════════════════════════════════════════════
  //  Limpieza — deja la base de datos impecable
  // ════════════════════════════════════════════════════════════════════

  /// Cierra la partida: cancela listeners, cierra WebRTC y borra la sala.
  Future<void> terminarPartida() async {
    if (_disposed) return;
    _disposed = true;

    // 1) Cancelar TODOS los listeners de Firebase.
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();

    // 2) Cerrar canal y peer connection.
    try {
      await _channel?.close();
    } catch (_) {}
    try {
      await _pc?.close();
    } catch (_) {}
    _channel = null;
    _pc = null;

    // 3) Borrar el nodo de la sala (solo el host es dueño de limpiarla).
    if (_roomId != null) {
      try {
        await _roomRef.onDisconnect().cancel();
        await _roomRef.remove();
      } catch (_) {}
    }

    status.value = P2PStatus.closed;
  }

  /// Libera notificadores. Llamar en dispose() del widget.
  void dispose() {
    terminarPartida();
    status.dispose();
    errorMessage.dispose();
  }
}
