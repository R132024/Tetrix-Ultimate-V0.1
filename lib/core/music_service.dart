import 'package:nowplaying/nowplaying.dart';
import 'package:nowplaying/nowplaying_track.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ForceValueNotifier<T> extends ChangeNotifier implements ValueListenable<T> {
  T _value;
  ForceValueNotifier(this._value);

  @override
  T get value => _value;

  set value(T newValue) {
    _value = newValue;
    notifyListeners();
  }

  void forceNotify() => notifyListeners();
}

class MusicService {
  static final MusicService instance = MusicService._internal();
  MusicService._internal();

  final ForceValueNotifier<NowPlayingTrack?> currentTrack = ForceValueNotifier(null);
  final ValueNotifier<Color> dominantColor = ValueNotifier(const Color(0xFF00E5FF)); // Default cyan

  Future<void> init() async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      final isEnabled = await NowPlaying.instance.isEnabled();
      if (!isEnabled) {
        await NowPlaying.instance.requestPermissions(force: true);
      }

      await NowPlaying.instance.start(resolveImages: true);
      NowPlaying.instance.stream.listen((track) async {
        
        // Notificamos inmediatamente a la UI con la nueva canción
        currentTrack.value = track;
        currentTrack.forceNotify();

        // Resolvemos imagen si hace falta
        if (track.imageNeedsResolving && !track.hasImage) {
          await track.resolveImage();
          // Notificamos de nuevo ahora que tiene imagen
          currentTrack.forceNotify();
        }
        
        // Actualizamos color de fondo casi a coste cero
        if (track.title != null) {
          final hash = "${track.title}${track.artist}".hashCode;
          final colorIndex = hash.abs() % Colors.primaries.length;
          final newColor = Colors.primaries[colorIndex];
          dominantColor.value = newColor;
        }
      });
    } catch (e) {
      debugPrint("MusicService init error: $e");
    }
  }
}
