import 'package:flutter/material.dart';

class GameGestureDetector extends StatefulWidget {
  const GameGestureDetector({
    super.key,
    required this.child,
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.onHardDrop,
    required this.onHoldPiece,
    required this.onRotateClockwise,
    required this.onFastDrop,
  });

  final Widget child;
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;
  final VoidCallback onHardDrop;
  final VoidCallback onHoldPiece;
  final VoidCallback onRotateClockwise;
  final ValueChanged<bool> onFastDrop;

  @override
  State<GameGestureDetector> createState() => _GameGestureDetectorState();
}

class _GameGestureDetectorState extends State<GameGestureDetector> {
  double _panStartX = 0;
  double _panStartY = 0;
  double _accumulatedPanX = 0;
  bool _panVerticalTriggered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) {
        _panStartX = details.localPosition.dx;
        _panStartY = details.localPosition.dy;
        _accumulatedPanX = 0;
        _panVerticalTriggered = false;
      },
      onPanUpdate: (details) {
        if (_panVerticalTriggered) return;

        final dy = details.localPosition.dy - _panStartY;
        final dx = details.localPosition.dx - _panStartX;

        if (dy.abs() > 40 && dy.abs() > dx.abs()) {
          _panVerticalTriggered = true;
          if (dy > 0) {
            widget.onHardDrop();
          } else {
            widget.onHoldPiece();
          }
          return;
        }

        _accumulatedPanX += details.delta.dx;
        const threshold = 30.0;
        while (_accumulatedPanX > threshold) {
          widget.onMoveRight();
          _accumulatedPanX -= threshold;
        }
        while (_accumulatedPanX < -threshold) {
          widget.onMoveLeft();
          _accumulatedPanX += threshold;
        }
      },
      onTap: widget.onRotateClockwise,
      onLongPressStart: (_) => widget.onFastDrop(true),
      onLongPressEnd: (_) => widget.onFastDrop(false),
      onLongPressCancel: () => widget.onFastDrop(false),
      child: widget.child,
    );
  }
}
