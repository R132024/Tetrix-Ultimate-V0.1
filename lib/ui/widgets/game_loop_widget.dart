import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:cubix_blast/core/game_engine.dart';

/// Ticker-based game loop widget.
///
/// Drives the [GameEngine.update] method at a fixed timestep using
/// a Flutter [Ticker]. Both game modes use this same widget.
class GameLoopWidget extends StatefulWidget {
  const GameLoopWidget({
    super.key,
    required this.engine,
    required this.frameNotifier,
    required this.builder,
  });

  /// The game engine to drive.
  final GameEngine engine;

  /// Notifier that increments each frame (triggers CustomPainter repaints).
  final ValueNotifier<int> frameNotifier;

  /// The builder function that builds the game screen layout.
  /// Rebuilt every frame.
  final WidgetBuilder builder;

  @override
  State<GameLoopWidget> createState() => _GameLoopWidgetState();
}

class _GameLoopWidgetState extends State<GameLoopWidget>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  double _accumulator = 0;
  static const double _fixedStep = 1.0 / 60.0; // 60 UPS

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    double dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;

    // Si hubo una pausa larga (ej. ver anuncio publicitario, minimizar app, etc.),
    // limitamos dt y limpiamos acumulador para evitar que el juego corra a 5x velocidad.
    if (dt > 0.1) {
      dt = _fixedStep;
      _accumulator = 0;
    } else {
      _accumulator += dt;
    }

    if (_accumulator > _fixedStep * 2) {
      _accumulator = _fixedStep * 2;
    }

    // Fixed-timestep loop with accumulator
    int steps = 0;
    while (_accumulator >= _fixedStep && steps < 5) {
      widget.engine.update(_fixedStep);
      _accumulator -= _fixedStep;
      steps++;
    }

    // Trigger repaint
    widget.frameNotifier.value++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
