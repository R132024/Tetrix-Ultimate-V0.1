import 'package:flutter/material.dart';
import 'package:cubix_blast/theme/game_themes.dart';

class BlockPainterUtils {
  /// Dibuja un bloque con el estilo visual correspondiente al tema
  static void drawBlock({
    required Canvas canvas,
    required Rect rect,
    required Color color,
    required PieceStyle style,
    bool isGhost = false,
  }) {
    if (isGhost) {
      _drawGhostBlock(canvas, rect, color);
      return;
    }

    switch (style) {
      case PieceStyle.classic:
        _drawClassicBlock(canvas, rect, color);
        break;
      case PieceStyle.neon:
        _drawNeonBlock(canvas, rect, color);
        break;
      case PieceStyle.metallic:
        _drawMetallicBlock(canvas, rect, color);
        break;
      case PieceStyle.matrix:
        _drawMatrixBlock(canvas, rect, color);
        break;
    }
  }

  static void _drawGhostBlock(Canvas canvas, Rect rect, Color color) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rrect, paint);

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint);
  }

  static void _drawClassicBlock(Canvas canvas, Rect rect, Color color) {
    // Dibujado / Cartoon style: flat color, thick black outline, white shine top-left
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2));
    
    // Fill
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint);

    // Thick black border
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(rrect, borderPaint);

    // White shine (top left inside)
    final shinePath = Path();
    shinePath.moveTo(rect.left + 4, rect.bottom - 6);
    shinePath.lineTo(rect.left + 4, rect.top + 4);
    shinePath.lineTo(rect.right - 6, rect.top + 4);

    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    
    canvas.drawPath(shinePath, shinePaint);
  }

  static void _drawNeonBlock(Canvas canvas, Rect rect, Color color) {
    // Neon style: dark inside, glowing thick border, bright core
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

    // Glow shadow
    final glowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawRRect(rrect, glowPaint);

    // Dark interior fill
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint);

    // Bright solid outline
    final outlinePaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(rrect, outlinePaint);

    // Inner white core
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRRect(rrect, corePaint);
  }

  static void _drawMetallicBlock(Canvas canvas, Rect rect, Color color) {
    // Metallic style: linear gradient for brushed metal look, bevel effect
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    // Base Gradient
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        _lighten(color, 0.4),
        color,
        _darken(color, 0.4),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final fillPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint);

    // Bevel highlights
    final topHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    final bottomShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // We can simulate bevel with lines
    canvas.drawLine(rect.topLeft, rect.topRight, topHighlight);
    canvas.drawLine(rect.topLeft, rect.bottomLeft, topHighlight);
    canvas.drawLine(rect.bottomLeft, rect.bottomRight, bottomShadow);
    canvas.drawLine(rect.topRight, rect.bottomRight, bottomShadow);
  }

  static void _drawMatrixBlock(Canvas canvas, Rect rect, Color color) {
    // Matrix style: very dark fill, green/colored outer stroke, matrix text inside
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2));

    // Glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawRRect(rrect, glowPaint);

    // Dark interior fill
    final fillPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint);

    // Grid stroke
    final outlinePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, outlinePaint);

    // Draw fake matrix numbers using paths for performance
    final textPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Draw some 1s and 0s roughly
    final cx = rect.left + rect.width / 2;
    final cy = rect.top + rect.height / 2;
    
    // Zero
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 4, cy - 4), width: 3, height: 6),
      textPaint,
    );
    // One
    canvas.drawLine(
      Offset(cx + 4, cy - 6),
      Offset(cx + 4, cy),
      textPaint,
    );
    // Zero
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 6), width: 3, height: 6),
      textPaint,
    );
  }

  // Utils
  static Color _lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  static Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}

