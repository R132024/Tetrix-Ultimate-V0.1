import 'package:cubix_blast/core/i18n.dart';
import 'package:cubix_blast/core/ad_service.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cubix_blast/casino/logic/casino_engine.dart';
import 'package:cubix_blast/core/score_manager.dart';
import 'package:cubix_blast/core/audio_service.dart';
import 'package:cubix_blast/core/music_service.dart';
import 'package:cubix_blast/theme/game_themes.dart';
import 'package:cubix_blast/casino/ui/casino_painter.dart';
import 'package:cubix_blast/core/game_engine.dart';
import 'package:cubix_blast/ui/widgets/game_loop_widget.dart';
import 'package:cubix_blast/ui/widgets/overlay_menu.dart';
import 'package:cubix_blast/ui/widgets/game_over_modal.dart';
import 'package:cubix_blast/ui/widgets/next_piece_preview.dart';
import 'package:cubix_blast/casino/ui/casino_shop_modal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cubix_blast/casino/logic/charms.dart';

import 'package:cubix_blast/ui/widgets/game_gesture_detector.dart';
import 'package:cubix_blast/ui/widgets/audio_visualizer_bg.dart';
import 'package:cubix_blast/ui/widgets/hold_piece_preview.dart';

/// Casino mode game screen.
class CasinoScreen extends StatefulWidget {
  const CasinoScreen({super.key});

  @override
  State<CasinoScreen> createState() => _CasinoScreenState();
}

class _CasinoScreenState extends State<CasinoScreen>
    with WidgetsBindingObserver {
  late final CasinoEngine _engine;
  final ValueNotifier<int> _frameNotifier = ValueNotifier(0);
  final FocusNode _focusNode = FocusNode();

  final double _accumulatedPanX = 0;
  final bool _panVerticalTriggered = false;

  bool _initializedLevel = false;
  int _startingLevel = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = CasinoEngine();
    _engine.reset();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedLevel) {
      _initializedLevel = true;
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      _startingLevel = args?['initialLevel'] as int? ?? 1;
      _engine.reset(initialLevel: _startingLevel);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _frameNotifier.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive ||
            state == AppLifecycleState.hidden) &&
        _engine.state.status == GameStatus.playing) {
      _engine.togglePause();
    }
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        _engine.moveLeft();
      case LogicalKeyboardKey.arrowRight:
        _engine.moveRight();
      case LogicalKeyboardKey.arrowUp:
        _engine.rotateClockwise();
      case LogicalKeyboardKey.arrowDown:
        _engine.softDrop();
      case LogicalKeyboardKey.space:
        _engine.hardDrop();
      case LogicalKeyboardKey.keyP:
      case LogicalKeyboardKey.escape:
        _engine.togglePause();
      case LogicalKeyboardKey.keyR:
        if (_engine.state.status == GameStatus.gameOver) {
          _engine.reset(initialLevel: _startingLevel);
        }
      default:
        break;
    }
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
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('CASINO'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AudioService.instance.playBoton();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.pause, color: Colors.white),
            tooltip: 'Pausa',
            onPressed: () {
              AudioService.instance.playBoton();
              _engine.togglePause();
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: AudioService.instance.bgmNotifier,
            builder: (context, isEnabled, child) {
              return IconButton(
                icon: Icon(isEnabled ? Icons.music_note : Icons.music_off, color: Colors.white70),
                onPressed: () {
                  AudioService.instance.playBoton();
                  AudioService.instance.toggleBgm();
                },
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: AudioService.instance.sfxNotifier,
            builder: (context, isEnabled, child) {
              return IconButton(
                icon: Icon(isEnabled ? Icons.volume_up : Icons.volume_off, color: Colors.white70),
                onPressed: () {
                  AudioService.instance.playBoton();
                  AudioService.instance.toggleSfx();
                },
              );
            },
          ),
        ],
      ),
      body: GameGestureDetector(
        onMoveLeft: _engine.moveLeft,
        onMoveRight: _engine.moveRight,
        onHardDrop: _engine.hardDrop,
        onHoldPiece: _engine.holdPiece,
        onRotateClockwise: _engine.rotateClockwise,
        onFastDrop: _engine.setFastDrop,
        child: KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKey,
          child: GameLoopWidget(
            engine: _engine,
            frameNotifier: _frameNotifier,
            builder: (context) => Stack(children: [_buildLayout()]),
          ),
        ),
      ),
    );
  }

  Widget _buildLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight - 140;
        final maxW = constraints.maxWidth;
        final double canvasW = (maxH * 0.5).clamp(0.0, maxW * 0.95).toDouble();
        final canvasH = canvasW * 2; // 10:20 ratio

        final theme = GameThemes.getTheme(ScoreManager.currentTheme);
        final currentColor = Theme.of(context).colorScheme.primary;
        final tempo = 1.0 + (_engine.state.level * 0.15);

        return Stack(
          children: [
            Positioned.fill(
              child: ValueListenableBuilder<Color>(
                valueListenable: MusicService.instance.dominantColor,
                builder: (context, dominantColor, child) {
                  return AudioVisualizerBg(
                    color: dominantColor,
                    tempoMultiplier: tempo,
                  );
                },
              ),
            ),
            SafeArea(
              child: Column(
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: _frameNotifier,
                  builder: (context, frame, _) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          HoldPiecePreview(
                            piece: _engine.heldPiece,
                            canHold: _engine.canHold,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'RONDA ${_engine.currentRound}',
                                  style: const TextStyle(color: Color(0xFFFFD600), fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0, end: _engine.roundScore.toDouble()),
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, val, child) {
                                    final currentScore = val.toInt();
                                    final progress = (currentScore / _engine.targetScore).clamp(0.0, 1.0);
                                    return Column(
                                      children: [
                                        LinearProgressIndicator(
                                          value: progress,
                                          backgroundColor: Colors.white24,
                                          color: const Color(0xFF00E5FF),
                                          minHeight: 8,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$currentScore / ${_engine.targetScore}',
                                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Text(
                                      'FICHAS: \$${_engine.runMoney}',
                                      style: GoogleFonts.vt323(color: const Color(0xFFFFB000), fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'DEUDA (${_engine.roundInCycle}/3): \$${_engine.targetDebt}',
                                      style: GoogleFonts.vt323(color: const Color(0xFFFF1744), fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          NextPiecePreview(piece: _engine.nextPiece),
                        ],
                      ),
                    );
                  },
                ),
                Expanded(
                  child: Center(
                    child: ValueListenableBuilder<int>(
                      valueListenable: _frameNotifier,
                      builder: (context, frame, child) {
                        return Transform.translate(
                          offset: Offset(
                            _engine.shakeTimer > 0
                                ? (sin(_engine.state.elapsedSeconds * 50) *
                                      15 *
                                      _engine.shakeTimer)
                                : 0,
                            _engine.shakeTimer > 0
                                ? (cos(_engine.state.elapsedSeconds * 60) *
                                      15 *
                                      _engine.shakeTimer)
                                : 0,
                          ),
                          child: child,
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          width: canvasW,
                          height: canvasH,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: CasinoPainter(
                                  engine: _engine,
                                  repaint: _frameNotifier,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_engine.activeCharms.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _engine.activeCharms.length,
                      itemBuilder: (context, index) {
                        final charm = _engine.activeCharms[index];
                        return GestureDetector(
                          onTap: () => _showCharmModal(context, charm),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              border: Border.all(color: Colors.white54, width: 2),
                            ),
                            child: Text(charm.icon, style: const TextStyle(fontSize: 24)),
                          ),
                        );
                      },
                    ),
                  )
                ],
                const SizedBox(height: 16),
              ],
            ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: _frameNotifier,
              builder: (context, frame, child) {
                if (_engine.reviveCountdown > 0) {
                  return Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Center(
                      child: Text(
                        _engine.reviveCountdown.ceil().toString(),
                        style: TextStyle(
                          fontSize: 120,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Theme.of(context).colorScheme.primary, 
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                if (_engine.state.status == GameStatus.gameOver) {
                  return GameOverModal(
                    state: _engine.state,
                    mode: 'classic',
                    onRetry: () {
                      AdService.instance.showInterstitialIfNeeded();
                      _engine.reset(initialLevel: _startingLevel);
                    },
                    onMenu: () {
                      AdService.instance.showInterstitialIfNeeded();
                      Navigator.of(context).pop();
                    },
                    onResume: () {},
                    onRevive: () async {
                      final success = await AdService.instance.showRewardedAd();
                      if (success) {
                        _engine.revive();
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
                  );
                } else if (_engine.state.status == GameStatus.roundCleared) {
                  return Positioned.fill(
                    child: CasinoShopModal(
                      engine: _engine,
                      onNextRound: () {
                        _engine.nextRound();
                      },
                      onGameOver: () {
                        _engine.forceGameOver();
                      },
                    ),
                  );
                } else if (_engine.state.status == GameStatus.paused) {
                  return OverlayMenu(
                    title: context.t('paused'),
                    score: _engine.state.score,
                    bestScore: _engine.highScore,
                    onResume: _engine.togglePause,
                    onRestart: () => _engine.reset(initialLevel: _startingLevel),
                    onHome: () => Navigator.of(context).pop(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        );
      },
    );
  }

  void _showCharmModal(BuildContext context, Charm charm) {
    if (_engine.state.status == GameStatus.playing) {
      _engine.togglePause();
    }
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF051005),
              border: Border.all(color: const Color(0xFF4AF626), width: 4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4AF626).withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  charm.icon,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 12),
                Text(
                  charm.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.vt323(color: const Color(0xFFFFB000), fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  charm.description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.vt323(color: Colors.white, fontSize: 20),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4AF626),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      'CERRAR',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.pressStart2p(color: Colors.black, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
