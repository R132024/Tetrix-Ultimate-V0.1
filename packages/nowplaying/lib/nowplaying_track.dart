import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

import 'nowplaying.dart';

enum _NowPlayingImageResolutionState { unresolved, resolving, resolved }

/// A container for metadata around a single track state
///
/// Artist, album, track, duration, genre, source, progress
class NowPlayingTrack {
  static final NowPlayingTrack notPlaying = NowPlayingTrack(id: 'notplaying');
  static final NowPlayingTrack loading = NowPlayingTrack(id: 'loading');

  static final _essentialRegExp = RegExp(r'\(.*\)|\[.*\]');

  static final _images = _LruMap<String, ImageProvider?>(size: 3);
  static final _resolutionStates =
      _LruMap<String, _NowPlayingImageResolutionState?>(size: 3);
  static final _icons = _LruMap<String?, ImageProvider>();

  final String id;
  final String? title;
  final String? album;
  final String? artist;
  final String? source;
  final Duration duration;
  final Duration position;
  final DateTime createdAt;
  final NowPlayingState state;

  /// How long the track been has been playing, as a `Duration`
  ///
  /// If the track is playing: how much had been played at the time the state
  /// was recorded, plus elapsed time since then
  ///
  /// If the track is not playing: how much had been played at the time the state
  /// was recorded
  Duration get progress {
    if (state == NowPlayingState.playing) {
      return position + DateTime.now().difference(createdAt);
    }
    return position;
  }

  String? get essentialAlbum => _essential(album);
  String? get essentialTitle => _essential(title);
  String? _essential(String? text) {
    if (text == null) return null;
    final String essentialText = text.replaceAll(_essentialRegExp, '').trim();
    return essentialText.isEmpty ? text : essentialText;
  }

  /// An image representing the app playing the track
  ImageProvider? get icon {
    if (isIOS) {
      return const AssetImage('assets/applemusic.png', package: 'nowplaying');
    }
    if (source == 'com.acmeandroid.listen') {
      return const AssetImage('assets/listenapp.png', package: 'nowplaying');
    }
    return _icons[source];
  }

  final isSpotify = false;
  bool get hasSpotifySource => source == 'com.spotify.music';

  bool get hasIcon => isIOS || _icons.containsKey(source);
  bool get hasImage => image != null;

  /// true if the image is being resolved, else false
  bool get isResolvingImage =>
      _resolutionState == _NowPlayingImageResolutionState.resolving;

  /// true if the image is empty and a resolution hasn't been attempted, else false
  bool get imageNeedsResolving =>
      _resolutionState == _NowPlayingImageResolutionState.unresolved;

  String get _imageId => '$title:$artist:$album';

  @override
  operator ==(other) =>
      other is NowPlayingTrack &&
      other.id == id &&
      other.progress == progress &&
      other.state == state;

  /// The image for the track, probably album art
  ///
  /// A bit of sophistry here: images are stored per album rather than per
  /// track, for efficiency, and shared.
  ImageProvider? get image => _images[_imageId];
  set image(ImageProvider? image) => _images[_imageId] = image;

  _NowPlayingImageResolutionState? get _resolutionState =>
      _resolutionStates[_imageId];
  set _resolutionState(_NowPlayingImageResolutionState? state) =>
      _resolutionStates[_imageId] = state;

  NowPlayingTrack({
    String? id,
    this.title,
    this.album,
    this.artist,
    this.duration = Duration.zero,
    this.state = NowPlayingState.stopped,
    this.source,
    this.position = Duration.zero,
    DateTime? createdAt,
  })  : id = id ?? Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Creates a track from json
  ///
  /// Returns the static `notPlaying` instance if player is stopped
  ///
  /// Creates image and icon art if not already present/resolved
  factory NowPlayingTrack.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return notPlaying;

    final state = NowPlayingState.values[json['state']];
    if (state == NowPlayingState.stopped) return notPlaying;

    final String imageId = '${json['title']}:${json['artist']}:${json['album']}';

    final Uint8List? imageData = json['image'];
    if (imageData is Uint8List) {
      _images[imageId] = MemoryImage(imageData);
    } else {
      final String? imageUri = json['imageUri'];
      if (imageUri?.startsWith('https://') == true) {
        _images[imageId] = NetworkImage(imageUri!);
      }
    }

    _resolutionStates[imageId] ??= _NowPlayingImageResolutionState.unresolved;

    final Uint8List? iconData = json['sourceIcon'];
    if (iconData is Uint8List) _icons[json['source']] ??= MemoryImage(iconData);

    return NowPlayingTrack(
      id: json['id'].toString(),
      title: json['title'],
      album: json['album'],
      artist: json['artist'],
      duration: Duration(milliseconds: json['duration'] ?? 0),
      position: Duration(milliseconds: json['position'] ?? 0),
      state: state,
      source: json['source'],
    );
  }

  /// Creates a copy of a track, largely so that the stream knows it's mutated
  NowPlayingTrack copy() => NowPlayingTrack(
        id: id,
        title: title,
        album: album,
        artist: artist,
        duration: duration,
        position: position,
        state: state,
        source: source,
        createdAt: createdAt,
      );

  bool get isNotReported => this == notPlaying;
  bool get isReported => !isNotReported;
  bool get isPlaying => state == NowPlayingState.playing;
  bool get isPaused => state == NowPlayingState.paused;
  bool get isStopped => state == NowPlayingState.stopped;

  @override
  String toString() => isStopped
      ? 'NowPlaying: -silence-'
      : 'NowPlaying:'
          'title: $title; '
          'artist: $artist; '
          'album: $album; '
          'duration: ${duration.inMilliseconds}ms; '
          'position: ${position.inMilliseconds}ms; '
          'has image: $hasImage; '
          'state: $state';

  Future<void> resolveImage() async {
    if (imageNeedsResolving && !hasImage) {
      _resolutionState = _NowPlayingImageResolutionState.resolving;
      image = await NowPlaying.instance.resolver?.resolve(this);
      _resolutionState = _NowPlayingImageResolutionState.resolved;
    }
  }
}

class _LruMap<K, V> {
  final int size;
  final List<K> _keys = [];
  final Map<K, V> _map = {};

  _LruMap({this.size = 5}) : assert(size > 0);

  V? operator [](K key) => _map[key];

  void operator []=(K key, V value) {
    _map[key] = value;
    _keys.remove(key);
    _keys.insert(0, key);
    if (_keys.length > size) {
      final K removedKey = _keys.removeLast();
      _map.remove(removedKey);
    }
  }

  void remove(K key) {
    _keys.remove(key);
    _map.remove(key);
  }

  bool containsKey(K key) => _map.containsKey(key);
}
