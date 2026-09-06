import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/ad_service.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/home_screen.dart';
import 'classic/ui/classic_screen.dart';
import 'arena/ui/arena_screen.dart';
import 'power/ui/power_screen.dart';
import 'package:cubix_blast/ui/screens/shop_screen.dart';
import 'package:cubix_blast/casino/ui/casino_screen.dart';
import 'package:cubix_blast/core/score_manager.dart';
import 'package:cubix_blast/core/music_service.dart';
import 'package:cubix_blast/core/audio_service.dart';
import 'package:cubix_blast/multiplayer/ui/multiplayer_lobby_screen.dart';
import 'package:cubix_blast/multiplayer/ui/multiplayer_screen.dart';

import 'package:cubix_blast/core/player_manager.dart';
import 'package:cubix_blast/core/mission_manager.dart';
import 'package:cubix_blast/core/daily_rewards_manager.dart';
import 'package:cubix_blast/core/iap_service.dart';
import 'package:cubix_blast/core/i18n.dart';
import 'package:cubix_blast/online/ui/online_lobby_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cubix_blast/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await ScoreManager.init();
  await PlayerManager.init();
  await MissionManager.init();
  await DailyRewardsManager.init();
  await IAPService.instance.init();
  await LocaleController.instance.init();
  // Firebase es necesario solo para el modo Online (signaling). Si no está
  // configurado aún, la app sigue funcionando en los modos offline.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase no inicializado (modo offline): $e');
  }
  MusicService.instance.init(); // non-blocking request
  // AudioService initializes internally on first access
  AudioService.instance.playBgm('audio/puzzlemenu.mp3');

  // Inicializar Google Mobile Ads y cargar anuncios
  MobileAds.instance.initialize();
  AdService.instance.initialize();

  runApp(const CubixBlastApp());
}

class CubixBlastApp extends StatelessWidget {
  const CubixBlastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      builder: (context) => MaterialApp(
        title: 'CubixBlast: Puzzle Game',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme(const Color(0xFF00E5FF)),
        initialRoute: '/',
        routes: {
          '/': (_) => const HomeScreen(),
          '/classic': (_) => const ClassicScreen(),
          '/casino': (_) => const CasinoScreen(),
          '/arena': (_) => const ArenaScreen(),
          '/power': (_) => const PowerScreen(),
          '/multiplayer_lobby': (_) => const MultiplayerLobbyScreen(),
          '/multiplayer_match': (_) => const MultiplayerScreen(),
          '/online_lobby': (ctx) {
            final args = ModalRoute.of(ctx)?.settings.arguments;
            String? autoRoom;
            if (args is Map && args['autoJoinRoom'] is String) {
              autoRoom = args['autoJoinRoom'] as String;
            }
            return OnlineLobbyScreen(autoJoinRoom: autoRoom);
          },
          '/shop': (_) => const ShopScreen(),
        },
      ),
    );
  }
}
