import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cubix_blast/core/high_score_store.dart';
import 'package:cubix_blast/core/score_manager.dart';
import 'package:cubix_blast/core/audio_service.dart';
import 'package:cubix_blast/core/player_manager.dart';
import 'package:cubix_blast/core/mission_manager.dart';
import 'package:cubix_blast/core/music_service.dart';
import 'package:cubix_blast/ui/widgets/radial_menu.dart';
import 'package:cubix_blast/ui/widgets/particles_bg.dart';
import 'package:cubix_blast/ui/widgets/daily_rewards_modal.dart';
import 'package:cubix_blast/core/daily_rewards_manager.dart';
import 'package:cubix_blast/core/i18n.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:cubix_blast/online/logic/online_invite.dart';
import 'package:cubix_blast/core/ad_service.dart';
/// Home screen with animated mode selection menu and high scores.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;

  bool _showModes = false;
  int _startingLevel = 1;
  int _absoluteModeIndex = 0; // Para el scroll infinito
  double _accumulatedDelta = 0;
  List<Map<String, dynamic>> _leaderboard = [];

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  bool _hasNotifiedMusicMode = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _loadRecords();
    _initDeepLinks();
    MusicService.instance.currentTrack.addListener(_onMusicTrackChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (DailyRewardsManager.canClaimTodayNotifier.value && mounted) {
        _showDailyRewards();
      }
    });
  }

  void _showDailyRewards() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'daily_rewards',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const DailyRewardsModal();
      },
    );
  }

  void _onMusicTrackChanged() {
    final track = MusicService.instance.currentTrack.value;
    if (track != null && track.isPlaying && !_hasNotifiedMusicMode && mounted) {
      _hasNotifiedMusicMode = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showMusicModeAlert(context);
        }
      });
    }
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    // Escuchar enlaces cuando la app se abre por primera vez
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleUri(uri);
    });

    // Escuchar enlaces cuando la app ya está abierta en segundo plano
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri);
    });
  }

  void _handleUri(Uri uri) {
    final roomId = OnlineInvite.parseRoomId(uri);
    if (roomId != null && mounted) {
      Navigator.pushNamed(
        context,
        '/online_lobby',
        arguments: {'autoJoinRoom': roomId},
      );
    }
  }

  Future<void> _loadRecords() async {
    final scores = await HighScoreStore.getAllHighScores();
    if (mounted) {
      setState(() {
        _leaderboard = scores;
      });
    }
  }

  void _handleDrag(double delta) {
    _accumulatedDelta += delta;
    if (_accumulatedDelta < -40) {
      AudioService.instance.playBoton();
      setState(() => _absoluteModeIndex++);
      _accumulatedDelta = 0;
    } else if (_accumulatedDelta > 40) {
      AudioService.instance.playBoton();
      setState(() => _absoluteModeIndex--);
      _accumulatedDelta = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _linkSubscription?.cancel();
    MusicService.instance.currentTrack.removeListener(_onMusicTrackChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocaleController.instance.localeNotifier,
      builder: (context, locale, _) {
        return _buildContent(context);
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060A14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: ValueListenableBuilder<PlayerProfile>(
          valueListenable: PlayerManager.profileNotifier,
          builder: (context, profile, child) {
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F172A),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${profile.level}',
                      style: GoogleFonts.orbitron(
                        color: const Color(0xFF00E5FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100, // Fixed width for progress bar instead of Expanded
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NIVEL ${profile.level}',
                          style: GoogleFonts.orbitron(fontSize: 10, color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: profile.progress,
                          backgroundColor: Colors.white12,
                          color: const Color(0xFF00E5FF),
                          minHeight: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            );
          },
        ),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: AudioService.instance.bgmNotifier,
            builder: (context, isBgmEnabled, child) {
              // Si la música del juego está desactivada, asumimos que "Modo Música (Propia)" está ON
              final isExternalMusicMode = !isBgmEnabled;
              
              return GestureDetector(
                onTap: () {
                  AudioService.instance.playBoton();
                  AudioService.instance.toggleBgm();
                  
                  if (AudioService.instance.bgmNotifier.value == false) {
                    // Significa que apagó la BGM del juego -> Activó Modo Música
                    _showMusicModeAlert(context);
                  }
                },
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 140),
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isExternalMusicMode ? const Color(0xFFFF0055) : Colors.white24,
                      width: 2,
                    ),
                    boxShadow: isExternalMusicMode ? [
                      BoxShadow(
                        color: const Color(0xFFFF0055).withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ] : [],
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      children: [
                        Text(
                          isExternalMusicMode ? context.t('music_mode_on') : context.t('music_mode_off'),
                          style: GoogleFonts.orbitron(
                            color: isExternalMusicMode ? const Color(0xFFFF0055) : Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // El "switch" visual tipo iOS
                        Container(
                          width: 36,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isExternalMusicMode ? const Color(0xFFFF0055).withValues(alpha: 0.3) : Colors.white12,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            alignment: isExternalMusicMode ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isExternalMusicMode ? const Color(0xFFFF0055) : Colors.white54,
                                boxShadow: isExternalMusicMode ? [
                                  BoxShadow(color: const Color(0xFFFF0055), blurRadius: 5)
                                ] : [],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          ValueListenableBuilder<int>(
            valueListenable: ScoreManager.coinsNotifier,
            builder: (context, coins, child) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$coins',
                      style: GoogleFonts.orbitron(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: (details) {
          if (!_showModes) return;
          final isNarrow = MediaQuery.of(context).size.width < 600;
          if (isNarrow) return; // En móvil usamos swipe horizontal
          _handleDrag(details.delta.dy);
        },
        onHorizontalDragUpdate: (details) {
          if (!_showModes) return;
          final isNarrow = MediaQuery.of(context).size.width < 600;
          if (!isNarrow) return; // En web/tablet usamos swipe vertical
          _handleDrag(-details.delta.dx); // Si arrastra a la derecha (dx>0), wheel rota izquierda (index++)
        },
        onVerticalDragEnd: (_) {
          _accumulatedDelta = 0;
        },
        onHorizontalDragEnd: (_) {
          _accumulatedDelta = 0;
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: ParticlesBg(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                speedMultiplier: 0.3,
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: _showModes
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: _buildModeSelection(constraints),
                            )
                          : Center(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: _buildInitialBanner(),
                              ),
                            ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialBanner() {
    return Column(
      key: const ValueKey('banner'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTitle(),
        const SizedBox(height: 12),
        Text(
          context.t('app_subtitle'),
          style: GoogleFonts.orbitron(
            fontSize: 14,
            letterSpacing: 8,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 40),
        _buildMissionsPanel(),
        const SizedBox(height: 40),
        _buildLeaderboardTable(),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () {
            AudioService.instance.playBoton();
            setState(() {
              _showModes = true;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E5FF),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 8,
            shadowColor: const Color(0xFF00E5FF).withValues(alpha: 0.5),
          ),
          child: Text(
            context.t('play'),
            style: GoogleFonts.orbitron(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            AudioService.instance.playBoton();
            Navigator.pushNamed(context, '/shop').then((_) => _loadRecords());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: const Color(0xFFFFD600),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: const BorderSide(color: Color(0xFFFFD600), width: 1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.palette, size: 20),
              const SizedBox(width: 12),
              Text(
                context.t('theme_shop'),
                style: GoogleFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _translateMode(String mode) {
    switch (mode) {
      case 'classic':
        return context.t('mode_classic');
      case 'arena':
        return context.t('mode_arena');
      case 'power':
        return context.t('mode_power');
      case 'multiplayer':
        return context.t('mode_multi');
      case 'online':
        return context.t('mode_online');
      default:
        return mode;
    }
  }

  Widget _buildMissionsPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                context.t('daily_missions'),
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<List<DailyMission>>(
            valueListenable: MissionManager.missionsNotifier,
            builder: (context, missions, child) {
              if (missions.isEmpty) return const SizedBox.shrink();
              return Column(
                children: missions.map((mission) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                mission.title,
                                style: TextStyle(
                                  color: mission.isCompleted ? Colors.white54 : Colors.white,
                                  decoration: mission.isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            Text(
                              '${mission.current} / ${mission.target}',
                              style: TextStyle(
                                color: mission.isCompleted ? const Color(0xFF00E676) : const Color(0xFF00E5FF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: mission.progress,
                          backgroundColor: Colors.white12,
                          color: mission.isCompleted ? const Color(0xFF00E676) : const Color(0xFF00E5FF),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTable() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              context.t('scoreboard'),
              style: GoogleFonts.orbitron(
                fontSize: 16,
                color: Colors.white70,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_leaderboard.isEmpty)
            Center(
              child: Text(
                context.t('no_scores'),
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  color: Colors.white54,
                ),
              ),
            )
          else ...[
            // Header
            Row(
              children: [
                Expanded(flex: 2, child: _buildTableHeader(context.t('col_name'))),
                Expanded(flex: 3, child: _buildTableHeader(context.t('col_mode'))),
                Expanded(flex: 2, child: _buildTableHeader(context.t('col_level'))),
                Expanded(
                  flex: 3,
                  child: _buildTableHeader(context.t('col_score'), alignRight: true),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 20),
            // Rows
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _leaderboard.length,
              itemBuilder: (context, index) {
                final record = _leaderboard[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          record['name'] ?? '----',
                          style: GoogleFonts.orbitron(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          _translateMode(record['mode'] ?? ''),
                          style: GoogleFonts.orbitron(
                            fontSize: 12,
                            color: const Color(0xFF00E5FF),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${record['level'] ?? 1}',
                          style: GoogleFonts.orbitron(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          '${record['score'] ?? 0}',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.orbitron(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF00E676),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableHeader(String title, {bool alignRight = false}) {
    return Text(
      title,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: GoogleFonts.orbitron(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.white54,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildModeSelection(BoxConstraints constraints) {
    final isNarrow = constraints.maxWidth < 600;

    if (isNarrow) {
      return SizedBox(
        height: constraints.maxHeight,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: _buildRightPanel(isNarrow: true),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: (MediaQuery.of(context).size.height * 0.4).clamp(200.0, 300.0), 
              width: double.infinity,
              child: Align(
                alignment: Alignment.center,
                child: RadialModeMenu(
                    isBottom: true,
                    selectedIndex: _absoluteModeIndex,
                    onSelected: (index) {
                      AudioService.instance.playBoton();
                      setState(() => _absoluteModeIndex = index);
                    },
                    onRandomPressed: () {
                      AudioService.instance.playBoton();
                      final currentMod = _absoluteModeIndex % 6;
                      final realCurrentMod = currentMod < 0 ? currentMod + 6 : currentMod;
                      final targetMod = Random().nextInt(3);
                      int steps = targetMod - realCurrentMod;
                      if (steps <= 0) steps += 6;
                      setState(() => _absoluteModeIndex += steps);
                    },
                    items: _getMenuItems(),
                  ),
                ),
              ),
            ],
          ),
        );
      }

        // Diseño original para pantallas anchas
        return SizedBox(
          height: 500,
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Transform.translate(
                  offset: const Offset(-107, 0),
                  child: SizedBox(
                    height: 500,
                    width: double.infinity,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: RadialModeMenu(
                        selectedIndex: _absoluteModeIndex,
                        onSelected: (index) {
                          AudioService.instance.playBoton();
                          setState(() => _absoluteModeIndex = index);
                        },
                        onRandomPressed: () {
                          AudioService.instance.playBoton();
                          final currentMod = _absoluteModeIndex % 6;
                          final realCurrentMod = currentMod < 0 ? currentMod + 6 : currentMod;
                          final targetMod = Random().nextInt(3);
                          int steps = targetMod - realCurrentMod;
                          if (steps <= 0) steps += 6;
                          setState(() => _absoluteModeIndex += steps);
                        },
                        items: _getMenuItems(),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: _buildRightPanel(isNarrow: false),
                ),
              ),
            ],
          ),
        );
  }

  List<RadialMenuItem> _getMenuItems() {
    return [
      RadialMenuItem(
        title: context.t('mode_classic'),
        icon: Icons.grid_on,
        baseColor: const Color(0xFF00E5FF),
        highlightColor: const Color(0xFF00B8D4),
      ),
      RadialMenuItem(
        title: 'Casino',
        icon: Icons.casino,
        baseColor: const Color(0xFF00E676),
        highlightColor: const Color(0xFF00C853),
      ),
      RadialMenuItem(
        title: context.t('mode_arena'),
        icon: Icons.hourglass_bottom,
        baseColor: const Color(0xFFFF3D00),
        highlightColor: const Color(0xFFDD2C00),
      ),
      RadialMenuItem(
        title: context.t('mode_power'),
        icon: Icons.bolt,
        baseColor: const Color(0xFFFFD600),
        highlightColor: const Color(0xFFFFAB00),
      ),
      RadialMenuItem(
        title: context.t('mode_multi'),
        icon: Icons.wifi_tethering,
        baseColor: const Color(0xFFD500F9),
        highlightColor: const Color(0xFFAA00FF),
      ),
      RadialMenuItem(
        title: context.t('mode_config'),
        icon: Icons.settings,
        baseColor: Colors.grey,
        highlightColor: Colors.white,
      ),
    ];
  }

  Widget _buildRightPanel({bool isNarrow = false}) {
    // Definimos información estática para cada modo
    final modesInfo = [
      {
        'title': context.t('title_classic'),
        'desc': context.t('desc_classic'),
        'color': const Color(0xFF00E5FF),
        'route': '/classic',
      },
      {
        'title': 'Modo Casino',
        'desc': 'Sobrevive rondas, gana monedas y compra amuletos locos.',
        'color': const Color(0xFF00E676),
        'route': '/casino',
      },
      {
        'title': context.t('title_arena'),
        'desc': context.t('desc_arena'),
        'color': const Color(0xFFFF3D00),
        'route': '/arena',
      },
      {
        'title': context.t('title_power'),
        'desc': context.t('desc_power'),
        'color': const Color(0xFFFFD600),
        'route': '/power',
      },
      {
        'title': context.t('title_multi'),
        'desc': context.t('desc_multi'),
        'color': const Color(0xFFD500F9),
        'route': '/multiplayer_lobby',
      },
      {
        'title': context.t('title_settings'),
        'desc': '',
        'color': Colors.grey,
        'route': '',
      },
    ];

    // Obtenemos el índice real asegurando que sea positivo usando módulo
    int modIndex = _absoluteModeIndex % modesInfo.length;
    if (modIndex < 0) modIndex += modesInfo.length;

    final info = modesInfo[modIndex];
    final color = info['color'] as Color;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(modIndex),
        height: isNarrow ? 380 : 460,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                info['title'] as String,
                textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 2,
                shadows: [Shadow(color: color, blurRadius: 10)],
              ),
            ),
            ),
            if ((info['desc'] as String).isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                info['desc'] as String,
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 24),
            
            // Selector de Nivel o Sliders de Audio
            if (modIndex == 5) ...[
              Text(
                context.t('music'),
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
              ValueListenableBuilder<double>(
                valueListenable: AudioService.instance.bgmVolumeNotifier,
                builder: (context, vol, child) => Slider(
                  value: vol,
                  activeColor: color,
                  onChanged: (v) => AudioService.instance.setBgmVolume(v),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.t('sfx'),
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
              ValueListenableBuilder<double>(
                valueListenable: AudioService.instance.sfxVolumeNotifier,
                builder: (context, vol, child) => Slider(
                  value: vol,
                  activeColor: color,
                  onChanged: (v) => AudioService.instance.setSfxVolume(v),
                  onChangeEnd: (v) => AudioService.instance.playBoton(),
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              _buildLanguageSelector(color),
              const SizedBox(height: 24),
              Text(
                'Créditos de Audio:\nFX: Lolo_s\nMusic: Caret7',
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  fontSize: 10,
                  color: Colors.white30,
                  height: 1.5,
                ),
              ),
            ] else if (modIndex == 4) ...[
              // Panel Multijugador: acceso al modo Online 1v1 (Firebase + WebRTC)
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  AudioService.instance.playBoton();
                  final success = await AdService.instance.showRewardedAd();
                  if (success) {
                    if (context.mounted) {
                      Navigator.pushNamed(context, '/online_lobby');
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Video cancelado o no disponible aún.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.public, color: Color(0xFFD500F9)),
                label: Text(
                  context.t('title_online'),
                  style: GoogleFonts.orbitron(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFD500F9),
                    letterSpacing: 1,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD500F9), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ] else if (modIndex != 4) ...[
              Text(
                context.t('initial_level'),
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
                    onPressed: () {
                      if (_startingLevel > 1) {
                        AudioService.instance.playBoton();
                        setState(() => _startingLevel--);
                      }
                    },
                  ),
                  Container(
                    width: 60,
                    alignment: Alignment.center,
                    child: Text(
                      '$_startingLevel',
                      style: GoogleFonts.orbitron(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                    onPressed: () {
                      if (_startingLevel < 15) {
                        AudioService.instance.playBoton();
                        setState(() => _startingLevel++);
                      }
                    },
                  ),
                ],
              ),
            ] else ...[
               const SizedBox(height: 60), // Espacio para igualar la altura si no hay nivel
            ],

            // FIX: Antes había un `Spacer()` aquí. Este panel vive dentro de un
            // SingleChildScrollView (altura ilimitada), y `Spacer`/`Expanded`
            // exigen una altura ACOTADA. Eso disparaba la aserción
            // 'debugNeedsLayout' (pantalla roja). Se reemplaza por espacio fijo.
            const SizedBox(height: 24),

            // Botón Jugar
            if (modIndex != 5) ...[
              ElevatedButton(
                onPressed: () {
                  AudioService.instance.playBoton();
                  if (modIndex == 4) {
                    Navigator.pushNamed(context, info['route'] as String);
                  } else {
                    Navigator.pushNamed(context, info['route'] as String, arguments: {'initialLevel': _startingLevel}).then((_) => _loadRecords());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                  shadowColor: color.withValues(alpha: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      modIndex == 4 ? 'Local 1v1' : context.t('play'),
                      style: GoogleFonts.orbitron(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Botón Volver
            TextButton(
              onPressed: () {
                AudioService.instance.playBoton();
                setState(() => _showModes = false);
              },
              child: Text(
                context.t('back_home'),
                style: GoogleFonts.orbitron(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(Color color) {
    return Column(
      children: [
        Text(
          context.t('language'),
          textAlign: TextAlign.center,
          style: GoogleFonts.orbitron(fontSize: 12, color: Colors.white54),
        ),
        const SizedBox(height: 8),
        Container(
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1220),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: LocaleController.instance.code,
              dropdownColor: const Color(0xFF0B1220),
              icon: Icon(Icons.arrow_drop_down, color: color),
              isExpanded: true,
              items: LocaleController.supported.map((code) {
                return DropdownMenuItem<String>(
                  value: code,
                  child: Row(
                    children: [
                      Text(LocaleController.flag(code), style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        LocaleController.displayName(code),
                        style: GoogleFonts.orbitron(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newCode) {
                if (newCode != null) {
                  AudioService.instance.playBoton();
                  LocaleController.instance.setLocale(newCode);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                const Color(0xFF00E5FF),
                Color.lerp(
                  const Color(0xFFAA00FF),
                  const Color(0xFF00E5FF),
                  _pulseAnim.value,
                )!,
                const Color(0xFFFF1744),
              ],
            ).createShader(bounds),
            child: Text(
              'TETRIX ULTIMATE',
              maxLines: 1,
              style: GoogleFonts.orbitron(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMusicModeAlert(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFF0055).withValues(alpha: 0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF0055).withValues(alpha: 0.1),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.headphones,
                          color: const Color(0xFFFF0055),
                          size: 40,
                          shadows: [
                            Shadow(color: const Color(0xFFFF0055), blurRadius: 10)
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.t('music_mode_title'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            AudioService.instance.playBoton();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF0055).withValues(alpha: 0.9),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            context.t('got_it'),
                            style: GoogleFonts.orbitron(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
