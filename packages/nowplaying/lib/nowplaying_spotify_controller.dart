import 'package:flutter/material.dart';
import 'package:oauth2/oauth2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotify/spotify.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'nowplaying.dart';
import 'nowplaying_track.dart';

/// A controller for interactions with the Spotify API
class NowplayingSpotifyController {
  static const String _SPOTIFY_ACCESS_KEY = 'spotify.access.key';
  static const String _SPOTIFY_REFRESH_KEY = 'spotify.refresh.key';
  static const String _SPOTIFY_EXPIRATION_KEY = 'spotify.expiration.key';

  static const String _redirectUri = 'https://nowplaying.gomes.com/redirect';
  static const List<String> _scopes = [
    'user-read-email',
    'user-library-read',
    'user-read-recently-played',
    'user-read-currently-playing'
  ];

  late SharedPreferences _prefs;

  SpotifyTrack track = SpotifyTrack.notPlaying;
  SpotifyApi? _spotifyApi;
  String _clientId = '';
  String _clientSecret = '';

  late AuthorizationCodeGrant _grant;

  void setPrefs(SharedPreferences prefs) => _prefs = prefs;

  /// Sets the Spotify ClientID and ClientSecret for API interaction
  ///
  /// These can be created at https://developer.spotify.com/dashboard
  void setCredentials(
      {required String clientId, required String clientSecret}) {
    _clientId = clientId;
    _clientSecret = clientSecret;
  }

  /// true if the Spotify API is available for use
  bool get isEnabled => _clientId.isNotEmpty && _clientSecret.isNotEmpty;

  /// true if a valid connection to the API is currently available
  bool get isConnected {
    final int expiration = _prefs.getInt(_SPOTIFY_EXPIRATION_KEY) ?? 0;
    return expiration > DateTime.now().millisecondsSinceEpoch;
  }

  /// true if not connected
  bool get isUnconnected => !isConnected;

  /// Pushes a page onto the top of the Navigator stack containing a WebView
  /// holding the Spotify sign-in flow. Users must have a valid Spotify
  /// account and be signed in for Spotify nowplaying details to be available
  Future<bool?> signIn(context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (navReq) {
            if (navReq.url.startsWith(_redirectUri)) {
              _spotifyApi =
                  SpotifyApi.fromAuthCodeGrant(_grant, navReq.url);
              _saveCredentials();
              Navigator.of(context).pop(true);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(_authUri);

    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => WebViewWidget(controller: controller),
      ),
    );
  }

  /// Disconencts the Spotify API, disallowing further interrogation
  Future<void> disconnect() async {
    _spotifyApi = null;
    await Future.wait([
      _prefs.remove(_SPOTIFY_ACCESS_KEY),
      _prefs.remove(_SPOTIFY_REFRESH_KEY),
      _prefs.remove(_SPOTIFY_EXPIRATION_KEY),
    ]);
  }

  /// Gets an instance of the api.
  ///
  /// If the credentials have expired, a new set are seemlessly
  /// requested via the refresh token.
  Future<SpotifyApi?> api() async {
    final expiration = _prefs.getInt(_SPOTIFY_EXPIRATION_KEY) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (_spotifyApi == null || expiration < now) {
      final String? accessToken = _prefs.getString(_SPOTIFY_ACCESS_KEY);
      final String? refreshToken = _prefs.getString(_SPOTIFY_REFRESH_KEY);

      if (accessToken is String && refreshToken is String) {
        final creds = SpotifyApiCredentials(
          _clientId,
          _clientSecret,
          accessToken: accessToken,
          refreshToken: refreshToken,
          scopes: _scopes,
          expiration: DateTime.fromMillisecondsSinceEpoch(expiration),
        );

        try {
          _spotifyApi = SpotifyApi(creds);
        } on AuthorizationException catch (e) {
          print('ERROR: $e');
          _spotifyApi = null;
        }

        _saveCredentials();
      }
    }

    return _spotifyApi;
  }

  void _saveCredentials() async {
    if (_spotifyApi is SpotifyApi) {
      final SpotifyApiCredentials creds =
          await _spotifyApi!.getCredentials();
      _prefs.setString(_SPOTIFY_ACCESS_KEY, creds.accessToken!);
      _prefs.setString(_SPOTIFY_REFRESH_KEY, creds.refreshToken!);
      _prefs.setInt(
          _SPOTIFY_EXPIRATION_KEY, creds.expiration!.millisecondsSinceEpoch);
    }
  }

  Uri get _authUri {
    _grant = SpotifyApi.authorizationCodeGrant(
      SpotifyApiCredentials(_clientId, _clientSecret),
    );
    return _grant
        .getAuthorizationUrl(Uri.parse(_redirectUri), scopes: _scopes);
  }

  /// Returns the current track status from Spotify
  Future<NowPlayingTrack> currentTrack([_]) async {
    final api = await this.api();
    if (api is SpotifyApi) {
      try {
        final playbackState = await api.player.currentlyPlaying();
        if (playbackState.item is Track) {
          track = SpotifyTrack.from(playbackState);
        } else {
          track = SpotifyTrack.notPlaying;
        }
      } catch (e) {
        print('ERROR: $e');
        if (e is! ApiRateException) track = SpotifyTrack.notPlaying;
      }
    }
    return track;
  }
}

/// An extended NowPlayingTrack for Spotify API sourced tracks
class SpotifyTrack extends NowPlayingTrack {
  static final SpotifyTrack notPlaying = SpotifyTrack();
  static const _icon =
      AssetImage('assets/spotify.png', package: 'nowplaying');

  final String? _imageUrl;

  @override
  final isSpotify = true;

  @override
  ImageProvider? get image {
    if (super.image == null && _imageUrl is String) {
      super.image = NetworkImage(_imageUrl!);
    }
    return super.image;
  }

  SpotifyTrack({
    super.id,
    super.title,
    super.album,
    super.artist,
    String? image,
    super.source,
    super.createdAt,
    super.duration,
    super.position,
    super.state,
  })  : _imageUrl = image;

  factory SpotifyTrack.from(PlaybackState playbackState) {
    return SpotifyTrack(
      id: playbackState.item!.id,
      title: playbackState.item!.name,
      album: playbackState.item!.album?.name,
      artist: playbackState.item!.artists?.first.name,
      image: playbackState.item!.album?.images?.first.url,
      duration: playbackState.item!.duration ?? Duration.zero,
      position: Duration(milliseconds: playbackState.progressMs ?? 0),
      state: switch (playbackState.isPlaying) {
        true => NowPlayingState.playing,
        false => NowPlayingState.paused,
        null => NowPlayingState.stopped,
      },
      source: "Spotify",
    );
  }

  @override
  SpotifyTrack copy() => SpotifyTrack(
        id: id,
        title: title,
        album: album,
        image: _imageUrl,
        artist: artist,
        duration: duration,
        position: position,
        state: state,
        source: source,
        createdAt: createdAt,
      );

  @override
  ImageProvider get icon => SpotifyTrack._icon;

  @override
  bool get hasIcon => true;

  @override
  bool get isNotReported => this == notPlaying;
}
