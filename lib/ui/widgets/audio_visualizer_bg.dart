import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nowplaying/nowplaying_track.dart';
import 'package:cubix_blast/core/music_service.dart';
import 'particles_bg.dart';
import 'dart:ui';

/// A simulated audio visualizer background with animated bars.
class AudioVisualizerBg extends StatefulWidget {
  const AudioVisualizerBg({
    super.key,
    required this.color,
    this.tempoMultiplier = 1.0,
  });

  final Color color;
  final double tempoMultiplier;

  @override
  State<AudioVisualizerBg> createState() => _AudioVisualizerBgState();
}

class _AudioVisualizerBgState extends State<AudioVisualizerBg>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Repeating animation to drive the visualizer
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NowPlayingTrack?>(
      valueListenable: MusicService.instance.currentTrack,
      builder: (context, track, _) {
        // Ask package to resolve the image if it's missing (usually happens async)
        if (track != null &&
            !track.hasImage &&
            track.imageNeedsResolving &&
            !track.isResolvingImage) {
          track.resolveImage().then((_) {
            if (mounted) setState(() {});
          });
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            if (track != null && track.hasImage) ...[
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Image(
                    key: ValueKey(track.title),
                    image: ResizeImage(track.image!, width: 100), // Scale down before heavy blur
                    fit: BoxFit.cover,
                    color: Colors.black.withValues(alpha: 0.8),
                    colorBlendMode: BlendMode.darken,
                  ),
                ),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0.4,
                  child: Image(
                    key: ValueKey('${track.title}_fg'),
                    image: track.image!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
            ParticlesBg(
              color: widget.color,
              speedMultiplier: widget.tempoMultiplier,
            ),
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _VisualizerPainter(
                      time: _controller.value * 2 * pi * 10 * widget.tempoMultiplier,
                      baseColor: widget.color,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  _VisualizerPainter({required this.time, required this.baseColor});

  final double time;
  final Color baseColor;

  // Reduced from 32 to 16 bars to vastly improve entry-level device performance
  static const int barCount = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / barCount;
    final maxBarHeight = size.height * 0.4;

    // Cache the color once instead of recreating it or doing .withValues
    final paint = Paint()
      ..color = baseColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < barCount; i++) {
      // Simplier sine wave math (reduced from 3 trig calls to 2)
      final wave1 = sin(time * 0.5 + i * 0.4);
      final wave2 = cos(time * 0.8 - i * 0.2);

      double heightFactor = (wave1 + wave2) * 0.5;
      heightFactor = (heightFactor.abs() * 1.2).clamp(0.05, 1.0);

      // Fast random jitter
      final jitter = (sin(time * 5 + i * 13) * 0.1).abs();
      heightFactor = (heightFactor + jitter).clamp(0.05, 1.0);

      final currentHeight = maxBarHeight * heightFactor;

      final rect = Rect.fromLTWH(
        i * barWidth,
        size.height - currentHeight,
        barWidth - 2,
        currentHeight,
      );

      // Massive optimization: Using drawRect instead of drawRRect (no radius calculations for GPU)
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) => true;
}
