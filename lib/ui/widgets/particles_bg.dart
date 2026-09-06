import 'dart:math';
import 'package:flutter/material.dart';

class ParticlesBg extends StatefulWidget {
  const ParticlesBg({
    super.key,
    required this.color,
    required this.speedMultiplier,
  });
  final Color color;
  final double speedMultiplier;

  @override
  State<ParticlesBg> createState() => _ParticlesBgState();
}

class _ParticlesBgState extends State<ParticlesBg>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Reduced from 50 to 20 for massive performance gain
    for (int i = 0; i < 20; i++) {
      final alpha = _random.nextDouble() * 0.5 + 0.1;
      _particles.add(
        _Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          speed: _random.nextDouble() * 0.5 + 0.1,
          size: _random.nextDouble() * 3 + 1,
          // Precalculate the color here to avoid doing it 60 times a second
          cachedColor: widget.color.withValues(alpha: alpha),
        ),
      );
    }
  }

  @override
  void didUpdateWidget(covariant ParticlesBg oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color) {
      for (int i = 0; i < _particles.length; i++) {
        final alpha = _random.nextDouble() * 0.5 + 0.1;
        _particles[i].cachedColor = widget.color.withValues(alpha: alpha);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _ParticlesPainter(
              particles: _particles,
              time: _controller.value,
              speedMultiplier: widget.speedMultiplier,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.cachedColor,
  });
  final double x;
  double y;
  final double speed;
  final double size;
  Color cachedColor;
}

class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter({
    required this.particles,
    required this.time,
    required this.speedMultiplier,
  });

  final List<_Particle> particles;
  final double time;
  final double speedMultiplier;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final p in particles) {
      final yOffset = (time * p.speed * speedMultiplier * 10) % 1.0;
      double currentY = p.y - yOffset;
      if (currentY < 0) currentY += 1.0;

      paint.color = p.cachedColor;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(p.x * size.width, currentY * size.height),
          width: p.size,
          height: p.size,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true;
}
