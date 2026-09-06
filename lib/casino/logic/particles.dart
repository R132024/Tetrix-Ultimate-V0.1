import 'dart:math';
import 'package:flutter/material.dart';

class Particle {
  double x, y;
  double vx, vy;
  Color color;
  double life;
  final double maxLife;
  final double size;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.life,
    required this.size,
  }) : maxLife = life;

  void update(double dt) {
    vy += 800 * dt; // Gravedad
    x += vx * dt;
    y += vy * dt;
    life -= dt;
  }
}

class ParticleManager {
  final List<Particle> particles = [];
  final Random _rnd = Random();

  void update(double dt) {
    for (var p in particles) {
      p.update(dt);
    }
    particles.removeWhere((p) => p.life <= 0);
  }

  void spawnExplosion(double x, double y, int count) {
    for (int i = 0; i < count; i++) {
      final angle = _rnd.nextDouble() * 2 * pi;
      final speed = _rnd.nextDouble() * 300 + 100;
      particles.add(Particle(
        x: x,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 200, // Impulso extra hacia arriba
        color: _rnd.nextBool() ? const Color(0xFFFFD600) : const Color(0xFFFFAB00),
        life: _rnd.nextDouble() * 1.0 + 0.5,
        size: _rnd.nextDouble() * 4 + 4,
      ));
    }
  }

  void draw(Canvas canvas, Size size) {
    final paint = Paint();
    for (var p in particles) {
      paint.color = p.color.withValues(alpha: (p.life / p.maxLife).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
    }
  }
}
