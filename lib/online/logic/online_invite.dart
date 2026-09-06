/// Invitaciones por WhatsApp + Deep Linking para el modo Online 1v1.
library;

import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/i18n.dart';

class OnlineInvite {
  static const String baseUrl = 'https://beattris.app/join';

  /// Construye el link de invitación a una sala.
  static String buildLink(String roomId) => '$baseUrl?room=$roomId';

  /// Comparte la invitación (abre la hoja del sistema: WhatsApp, etc.).
  static Future<void> compartir(BuildContext context, String roomId) async {
    final link = buildLink(roomId);
    final text = context.t('invite_text', params: {'link': link});
    await Share.share(text, subject: 'BeatTris 1v1');
  }

  /// Extrae el parámetro `room` de un deep link entrante.
  /// Devuelve null si el URI no es una invitación válida.
  static String? parseRoomId(Uri uri) {
    if (!uri.path.contains('join')) return null;
    final room = uri.queryParameters['room'];
    if (room == null || room.isEmpty) return null;
    return room;
  }
}

/// ─────────────────────────────────────────────────────────────────────
///  CÓMO INTERCEPTAR EL DEEP LINK AL ABRIR DESDE WHATSAPP
/// ─────────────────────────────────────────────────────────────────────
///
/// 1) Agrega el paquete `app_links` (recomendado) al pubspec:
///       app_links: ^6.3.2
///
/// 2) Declara el dominio/esquema en Android (AndroidManifest.xml, dentro de
///    <activity android:name=".MainActivity">):
///
///       <intent-filter android:autoVerify="true">
///         <action android:name="android.intent.action.VIEW" />
///         <category android:name="android.intent.category.DEFAULT" />
///         <category android:name="android.intent.category.BROWSABLE" />
///         <data android:scheme="https"
///               android:host="beatblocks.app"
///               android:pathPrefix="/join" />
///       </intent-filter>
///
///    Y en iOS (Info.plist / Associated Domains) configura
///    `applinks:beatblocks.app`.
///
/// 3) En tu widget raíz, escucha los enlaces entrantes:
///
///       final _appLinks = AppLinks();
///
///       @override
///       void initState() {
///         super.initState();
///         // App abierta en frío desde el link:
///         _appLinks.getInitialLink().then(_handleUri);
///         // App ya abierta (warm):
///         _appLinks.uriLinkStream.listen(_handleUri);
///       }
///
///       void _handleUri(Uri? uri) {
///         if (uri == null) return;
///         final roomId = OnlineInvite.parseRoomId(uri);
///         if (roomId != null) {
///           // Navega al lobby y ejecuta automáticamente el flujo del Cliente:
///           navigatorKey.currentState?.pushNamed(
///             '/online_lobby',
///             arguments: {'autoJoinRoom': roomId},
///           );
///         }
///       }
///
///    El lobby (OnlineLobbyScreen) detecta `autoJoinRoom` y llama
///    `P2PGameManager.unirseAPartida(roomId)` sin que el usuario teclee nada.
