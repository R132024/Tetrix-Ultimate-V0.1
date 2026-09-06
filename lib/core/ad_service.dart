import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cubix_blast/core/score_manager.dart';
import 'dart:async';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // IDs proporcionados por el usuario
  final String _interstitialAdUnitId = Platform.isAndroid 
      ? 'ca-app-pub-6471503808295343/9371377537' 
      : 'ca-app-pub-3940256099942544/4411468910'; // Test ID for iOS

  List<String> get _rewardedAdUnitIds {
    // Forzado temporalmente a Test ID para verificar que el video bloquea el menú online
    return ['ca-app-pub-3940256099942544/5224354917']; // ID de prueba oficial Google
  }

  String get bannerAdUnitId {
    if (!kReleaseMode) {
      return 'ca-app-pub-3940256099942544/6300978111'; // ID de prueba oficial
    }
    return Platform.isAndroid
        ? 'ca-app-pub-6471503808295343/7215945920'
        : 'ca-app-pub-6471503808295343/7215945920'; // IOS pendiente
  }

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  DateTime? _lastInterstitialTime;
  // Solo muestra un intersticial máximo una vez cada 3 minutos
  static const int _interstitialCooldownSeconds = 180;

  void initialize() {
    // Pre-carga los anuncios para que estén listos cuando se necesiten
    _loadInterstitialAd();
    _loadRewardedAdAsync();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('InterstitialAd loaded.');
          _interstitialAd = ad;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadInterstitialAd(); // Cargar otro después de cerrarlo
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  void showInterstitialIfNeeded() {
    if (_interstitialAd == null) {
      _loadInterstitialAd();
      return;
    }
    
    final now = DateTime.now();
    if (_lastInterstitialTime != null) {
      final difference = now.difference(_lastInterstitialTime!).inSeconds;
      if (difference < _interstitialCooldownSeconds) {
        debugPrint('InterstitialAd on cooldown. Skipped.');
        return;
      }
    }

    _interstitialAd!.show();
    _interstitialAd = null;
    _lastInterstitialTime = now;
  }

  bool _isRewardedAdLoading = false;
  Completer<bool>? _rewardedAdLoadCompleter;
  int _currentRewardedAdIndex = 0;

  Future<bool> _loadRewardedAdAsync() async {
    if (_rewardedAd != null) return true;
    if (_isRewardedAdLoading) {
      if (_rewardedAdLoadCompleter != null) return _rewardedAdLoadCompleter!.future;
      return false;
    }

    _isRewardedAdLoading = true;
    _rewardedAdLoadCompleter = Completer<bool>();
    
    _tryLoadRewardedAdFromWaterfall();

    return _rewardedAdLoadCompleter!.future;
  }

  void _tryLoadRewardedAdFromWaterfall() {
    final adUnits = _rewardedAdUnitIds;
    if (_currentRewardedAdIndex >= adUnits.length) {
      // Se agotaron todos los IDs
      _currentRewardedAdIndex = 0;
      _isRewardedAdLoading = false;
      if (_rewardedAdLoadCompleter != null && !_rewardedAdLoadCompleter!.isCompleted) {
        _rewardedAdLoadCompleter!.complete(false);
      }
      _rewardedAdLoadCompleter = null;
      
      // Retry from beginning after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (_rewardedAd == null && !_isRewardedAdLoading) {
          _loadRewardedAdAsync();
        }
      });
      return;
    }

    final currentId = adUnits[_currentRewardedAdIndex];
    debugPrint('Intentando cargar RewardedAd con ID: $currentId (Intento ${_currentRewardedAdIndex + 1}/${adUnits.length})');

    RewardedAd.load(
      adUnitId: currentId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('RewardedAd cargado con éxito usando ID: $currentId');
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
          _currentRewardedAdIndex = 0; // Reiniciar índice para la próxima vez
          if (_rewardedAdLoadCompleter != null && !_rewardedAdLoadCompleter!.isCompleted) {
            _rewardedAdLoadCompleter!.complete(true);
          }
          _rewardedAdLoadCompleter = null;
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd falló con ID: $currentId. Error: $error');
          _currentRewardedAdIndex++;
          _tryLoadRewardedAdFromWaterfall(); // Intentar con el siguiente ID
        },
      ),
    );
  }

  /// Muestra un anuncio bonificado y devuelve un Future que se completa con true si el usuario obtuvo la recompensa.
  /// Si falla, usa un Intersticial como plan B. Si ambos fallan, regala la recompensa.
  Future<bool> showRewardedAd() async {
    if (ScoreManager.isPremium) {
      debugPrint('Usuario Premium. Regalo gratis instantáneo.');
      return true; // No mostrar anuncios
    }

    if (_rewardedAd == null) {
      debugPrint('RewardedAd is not ready yet. Waiting for load...');
      final loaded = await _loadRewardedAdAsync();
      
      // Si a pesar de esperar, AdMob dice "No fill" o falla:
      if (!loaded || _rewardedAd == null) {
        debugPrint('RewardedAd failed. Fallback to Interstitial...');
        
        // PLAN B: Usar Intersticial
        if (_interstitialAd != null) {
          final completer = Completer<bool>();
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadInterstitialAd();
              // Al ser intersticial no hay callback de recompensa, así que lo damos por hecho al cerrar.
              completer.complete(true); 
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _loadInterstitialAd();
              completer.complete(true); // Falla al mostrar, igual le damos el premio para no frustrar.
            },
          );
          _interstitialAd!.show();
          _interstitialAd = null;
          // Reiniciamos el cooldown para no spamearlo en la pantalla de gameOver normal
          _lastInterstitialTime = DateTime.now();
          return completer.future;
        } else {
          // PLAN C: Ambos fallaron (no hay internet o AdMob está vacío)
          // Regalar la recompensa instantáneamente para mantener al jugador feliz 100% de las veces.
          debugPrint('Both ads failed. Free revive!');
          return true;
        }
      }
    }

    bool earned = false;
    final completer = Completer<bool>();

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedAdAsync();
        completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewardedAdAsync();
        completer.complete(false);
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        earned = true;
      },
    );
    
    _rewardedAd = null;
    return completer.future;
  }
}
