import 'dart:math';
import 'package:flutter/material.dart';
import '../logic/power_engine.dart';

class PowerButtons extends StatelessWidget {
  final PowerEngine engine;
  final bool isMultiplayer;

  const PowerButtons({
    super.key,
    required this.engine,
    this.isMultiplayer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        _buildPowerButton(
          icon: Icons.hourglass_bottom,
          label: 'LENTA',
          cooldown: engine.slowMoCooldown,
          maxCooldown: 20.0,
          color: const Color(0xFF00E5FF),
          onTap: engine.activateSlowMo,
          isActive: engine.slowMoTimer > 0,
        ),
        _buildPowerButton(
          icon: Icons.flash_on,
          label: 'LÁSER',
          cooldown: engine.laserCooldown,
          maxCooldown: 30.0,
          color: const Color(0xFFFF1744),
          onTap: engine.activateLaser,
        ),
        _buildPowerButton(
          icon: Icons.local_fire_department,
          label: 'METEOR',
          cooldown: engine.meteoriteCooldown,
          maxCooldown: 40.0,
          color: const Color(0xFFFF6D00),
          onTap: engine.activateMeteorite,
        ),
        if (isMultiplayer) ...[
          _buildPowerButton(
            icon: Icons.layers,
            label: 'BASURA',
            cooldown: engine.garbagePowerCooldown,
            maxCooldown: 30.0,
            color: const Color(0xFFE040FB),
            onTap: engine.activateGarbagePower,
          ),
          _buildPowerButton(
            icon: Icons.fast_forward,
            label: 'ACELERAR',
            cooldown: engine.speedUpPowerCooldown,
            maxCooldown: 30.0,
            color: const Color(0xFF00E676),
            onTap: engine.activateSpeedUpPower,
          ),
        ],
      ],
    );
  }

  Widget _buildPowerButton({
    required IconData icon,
    required String label,
    required double cooldown,
    required double maxCooldown,
    required Color color,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final isCoolingDown = cooldown > 0;
    final progress = isCoolingDown ? cooldown / maxCooldown : 0.0;
    final activeColor = isCoolingDown ? Colors.grey : color;

    return GestureDetector(
      onTap: isCoolingDown ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? color.withValues(alpha: 0.25)
                        : const Color(0xFF0F172A),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: activeColor.withValues(alpha: isActive ? 0.9 : 0.5),
                      width: isActive ? 3 : 2,
                    ),
                    boxShadow: isCoolingDown
                        ? []
                        : [
                            BoxShadow(
                              color: activeColor.withValues(
                                alpha: isActive ? 0.5 : 0.2,
                              ),
                              blurRadius: isActive ? 16 : 10,
                              spreadRadius: isActive ? 4 : 2,
                            ),
                          ],
                  ),
                  child: Icon(icon, color: activeColor, size: 28),
                ),
                if (isCoolingDown)
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CustomPaint(
                      painter: _CooldownPainter(
                        progress: progress,
                        color: color.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                if (isCoolingDown)
                  Text(
                    cooldown.ceil().toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isCoolingDown
                  ? Colors.white30
                  : isActive
                      ? color
                      : Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CooldownPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CooldownPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = 2 * pi * progress;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CooldownPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
