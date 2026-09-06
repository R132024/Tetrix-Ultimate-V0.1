import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cubix_blast/online/logic/p2p_game_manager.dart';
import 'package:cubix_blast/core/audio_service.dart';
import 'package:cubix_blast/core/game_engine.dart';
import 'package:cubix_blast/classic/logic/classic_engine.dart';
import 'package:cubix_blast/arena/logic/arena_engine.dart';
import 'package:cubix_blast/power/logic/power_engine.dart';
import 'package:cubix_blast/classic/ui/classic_painter.dart';
import 'package:cubix_blast/arena/ui/arena_painter.dart';
import 'package:cubix_blast/power/ui/power_painter.dart';
import 'package:cubix_blast/ui/widgets/game_loop_widget.dart';
import 'package:cubix_blast/ui/widgets/score_board.dart';
import 'package:cubix_blast/ui/widgets/overlay_menu.dart';
import 'package:cubix_blast/ui/widgets/game_over_modal.dart';
import 'package:cubix_blast/ui/widgets/next_piece_preview.dart';

import 'package:cubix_blast/ui/widgets/game_gesture_detector.dart';
import 'package:cubix_blast/ui/widgets/audio_visualizer_bg.dart';
import 'package:cubix_blast/ui/widgets/hold_piece_preview.dart';
import 'package:cubix_blast/power/ui/power_buttons.dart';

class OnlineMatchScreen extends StatefulWidget {
  const OnlineMatchScreen({super.key, required this.manager});

  final P2PGameManager manager;

  @override
  State<OnlineMatchScreen> createState() => _OnlineMatchScreenState();
}

class _OnlineMatchScreenState extends State<OnlineMatchScreen>
    with WidgetsBindingObserver {
  late final GameEngine _engine;
  final ValueNotifier<int> _frameNotifier = ValueNotifier(0);
  final FocusNode _focusNode = FocusNode();

  bool _hasWon = false;
  bool _sentGameOver = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    final mode = widget.manager.selectedMode;
    if (mode == 'arena') {
      _engine = ArenaEngine();
    } else if (mode == 'power') {
      _engine = PowerEngine();
    } else {
      _engine = ClassicEngine();
    }
    
    _engine.onGarbageSent = (lines) {
      widget.manager.enviarLineaBasura(lines);
    };

    if (_engine is PowerEngine) {
      final pEngine = _engine;
      pEngine.onSendGarbagePower = (lines) => widget.manager.enviarLineaBasura(lines);
      pEngine.onSendSpeedUp = () => widget.manager.enviarSpeedUp();
    }
    
    _engine.reset();

    widget.manager.onGameEvent = (event) {
      if (event['t'] == 'garbage') {
        _engine.receiveGarbage(event['lines'] ?? 0);
      } else if (event['t'] == 'speedup') {
        if (_engine is PowerEngine) {
          (_engine).receiveSpeedUp();
        }
      } else if (event['t'] == 'gameover') {
        if (mounted) {
          _hasWon = true;
          _engine.forceGameOver();
          _frameNotifier.value++;
        }
      }
    };
    widget.manager.onRivalLeft = () {
      if (mounted) {
        setState(() {
          // Rival disconnected
        });
      }
    };
  }

  @override
  void dispose() {
    if (_engine.state.status == GameStatus.playing || _engine.state.status == GameStatus.paused) {
      widget.manager.enviarGameOver();
    }
    WidgetsBinding.instance.removeObserver(this);
    _frameNotifier.dispose();
    _focusNode.dispose();
    widget.manager.terminarPartida();
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
          _engine.reset();
        }
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060A14),
      appBar: AppBar(
        title: const Text('BATALLA ONLINE'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AudioService.instance.playBoton();
            Navigator.of(context).pop();
          },
        ),
        actions: [
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

        final currentColor = Theme.of(context).colorScheme.primary;
        final tempo = 1.0 + (_engine.state.level * 0.15);

        return Stack(
          children: [
            Positioned.fill(
              child: AudioVisualizerBg(
                color: currentColor,
                tempoMultiplier: tempo,
              ),
            ),
            Column(
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
                            child: ScoreBoard(
                              state: _engine.state,
                              highScore: _engine.highScore,
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // --- BARRA DE BASURA ---
                        if (_engine.pendingGarbage > 0)
                          Container(
                            width: 10,
                            height: canvasH,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              border: Border.all(color: Colors.redAccent, width: 1),
                            ),
                            alignment: Alignment.bottomCenter,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 10,
                              height: canvasH * (_engine.pendingGarbage / 20).clamp(0.0, 1.0),
                              color: Colors.red,
                            ),
                          ),
                        // --- MATRIZ DEL JUEGO ---
                        Transform.translate(
                          offset: Offset(
                            _engine.shakeTimer > 0
                                ? (Random().nextDouble() - 0.5) *
                                    15 *
                                    _engine.shakeTimer
                                : 0,
                            _engine.shakeTimer > 0
                                ? (Random().nextDouble() - 0.5) *
                                    15 *
                                    _engine.shakeTimer
                                : 0,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
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
                                  child: CustomPaint(
                                    painter: _getPainterForMode(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_engine is PowerEngine)
                  ValueListenableBuilder<int>(
                    valueListenable: _frameNotifier,
                    builder: (context, frame, child) {
                      return PowerButtons(
                        engine: _engine,
                        isMultiplayer: true,
                      );
                    },
                  ),
                const SizedBox(height: 16),
              ],
            ),
            ValueListenableBuilder<int>(
              valueListenable: _frameNotifier,
              builder: (context, frame, child) {
                if (_engine.state.status == GameStatus.gameOver) {
                  if (!_sentGameOver && !_hasWon) {
                    _sentGameOver = true;
                    widget.manager.enviarGameOver();
                  }
                  return GameOverModal(
                    state: _engine.state,
                    mode: 'online',
                    titleOverride: _hasWon ? '¡VICTORIA!' : 'FIN DE LA PARTIDA',
                    onRetry: () => Navigator.of(context).pop(), // Volver al lobby
                    onMenu: () => Navigator.of(context).pop(),
                    onResume: () {},
                  );
                } else if (_engine.state.status == GameStatus.paused) {
                  return OverlayMenu(
                    title: 'PAUSED',
                    score: _engine.state.score,
                    bestScore: _engine.highScore,
                    onResume: _engine.togglePause,
                    onRestart: () => _engine.reset(),
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

  CustomPainter _getPainterForMode() {
    final mode = widget.manager.selectedMode;
    if (mode == 'arena') {
      return ArenaPainter(engine: _engine as ArenaEngine, repaint: _frameNotifier);
    } else if (mode == 'power') {
      return PowerPainter(engine: _engine as PowerEngine, repaint: _frameNotifier);
    } else {
      return ClassicPainter(engine: _engine as ClassicEngine, repaint: _frameNotifier);
    }
  }
}
