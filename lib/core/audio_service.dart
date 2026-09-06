import 'package:audioplayers/audioplayers.dart';
import 'package:audio_session/audio_session.dart' as session;
import 'music_service.dart';

import 'package:flutter/widgets.dart';

class AudioService with WidgetsBindingObserver {
  static final AudioService instance = AudioService._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();

  final ValueNotifier<bool> bgmNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> sfxNotifier = ValueNotifier<bool>(true);
  
  final ValueNotifier<double> bgmVolumeNotifier = ValueNotifier<double>(0.5); // Default to 50%
  final ValueNotifier<double> sfxVolumeNotifier = ValueNotifier<double>(0.5);

  late Future<void> _initFuture;

  bool get isBgmEnabled => bgmNotifier.value;
  bool get isSfxEnabled => sfxNotifier.value;

  AudioService._internal() {
    _initFuture = _init();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      // App went to background
      pauseBgm();
    } else if (state == AppLifecycleState.resumed) {
      // App came back to foreground
      resumeBgm();
    }
  }

  Future<void> _init() async {
    try {
      final sessionInstance = await session.AudioSession.instance;
      await sessionInstance.configure(const session.AudioSessionConfiguration(
        avAudioSessionCategory: session.AVAudioSessionCategory.ambient,
        avAudioSessionCategoryOptions: session.AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: session.AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy: session.AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: session.AVAudioSessionSetActiveOptions.none,
      ));
      AudioPlayer.global.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: const {},
        ),
      ));
    } catch (e) {
      debugPrint("Audio session configuration error: $e");
    }

    // Configurar los reproductores de audioplayers
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    } catch (_) {}

    // Escuchar cambios en la música externa (usando el MusicService existente)
    MusicService.instance.currentTrack.addListener(_onExternalMusicChanged);
    _onExternalMusicChanged(); // Capturar estado inicial si ya había música
  }

  void _onExternalMusicChanged() {
    final track = MusicService.instance.currentTrack.value;
    final bool isExternalPlaying = track != null && track.isPlaying;
    
    if (isExternalPlaying) {
      if (bgmNotifier.value) {
        bgmNotifier.value = false;
      }
      pauseBgm();
    } else {
      if (!bgmNotifier.value) {
        bgmNotifier.value = true;
      }
      resumeBgm();
    }
  }

  Future<void> playBgm(String assetPath) async {
    await _initFuture;
    if (!isBgmEnabled) return;
    try {
      await _bgmPlayer.setVolume(bgmVolumeNotifier.value);
      await _bgmPlayer.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint("Error playing BGM: $e");
    }
  }

  Future<void> pauseBgm() async {
    await _initFuture;
    await _bgmPlayer.pause();
  }

  Future<void> resumeBgm() async {
    await _initFuture;
    final track = MusicService.instance.currentTrack.value;
    final bool isExternalPlaying = track != null && track.isPlaying;
    
    if (isBgmEnabled && !isExternalPlaying) {
      try {
        if (_bgmPlayer.state == PlayerState.paused) {
          await _bgmPlayer.resume();
        }
      } catch (e) {
        debugPrint("Error resuming BGM: $e");
      }
    }
  }

  Future<void> stopBgm() async {
    await _initFuture;
    await _bgmPlayer.stop();
  }

  Future<void> _playSfx(String assetName) async {
    if (!isSfxEnabled) return;
    try {
      await _initFuture;
      final player = AudioPlayer();
      await player.setVolume(sfxVolumeNotifier.value);
      await player.play(AssetSource('audio/$assetName'));
      // Liberar memoria cuando termine
      player.onPlayerComplete.listen((_) => player.dispose());
    } catch (e) {
      debugPrint("Error playing $assetName: $e");
    }
  }

  void playRomperFila() => _playSfx('romper_fila.mp3');
  void playLaser() => _playSfx('laser.mp3');
  void playMeteorito() => _playSfx('meteorito.mp3');
  void playPoderLento() => _playSfx('poder_lento.mp3');
  void playPausa() => _playSfx('pausa.mp3');
  void playPerderGanar() => _playSfx('perder_ganar.mp3');
  void playBoton() => _playSfx('boton.mp3');

  void toggleBgm() {
    bgmNotifier.value = !bgmNotifier.value;
    if (bgmNotifier.value) {
      resumeBgm();
      // Si queremos que inicie de una vez si estaba pausado:
      _bgmPlayer.play(AssetSource('audio/puzzlemenu.mp3'));
    } else {
      pauseBgm();
    }
  }

  void toggleSfx() {
    sfxNotifier.value = !sfxNotifier.value;
  }

  void setBgmVolume(double volume) {
    bgmVolumeNotifier.value = volume;
    _bgmPlayer.setVolume(volume);
  }

  void setSfxVolume(double volume) {
    sfxVolumeNotifier.value = volume;
  }
}
