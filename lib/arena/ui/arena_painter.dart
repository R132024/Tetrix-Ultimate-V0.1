import 'package:flutter/material.dart';
import 'package:cubix_blast/core/constants.dart';
import 'package:cubix_blast/arena/logic/arena_engine.dart';
import 'package:cubix_blast/ui/theme/app_theme.dart';
import 'package:cubix_blast/theme/game_themes.dart';

/// Renders the Arena mode sand grid using CustomPainter.
class ArenaPainter extends CustomPainter {
  ArenaPainter({required this.engine, required this.repaint})
    : super(repaint: repaint);

  final ArenaEngine engine;
  final ValueNotifier<int> repaint;

  @override
  void paint(Canvas canvas, Size size) {
    final grainW = size.width / sandColumns;
    final grainH = size.height / sandRows;
    final cellW = size.width / gridColumns;
    final cellH = size.height / gridRows;

    _drawBackground(canvas, size, cellW, cellH);
    _drawHardDropTrails(canvas, cellW, cellH);
    _drawSandGrains(canvas, grainW, grainH);
    _drawActivePiece(canvas, cellW, cellH);
    _drawBridgeFlash(canvas, grainW, grainH);
    _drawFloatingTexts(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size, double cellW, double cellH) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppTheme.gridBackground,
    );

    final linePaint = Paint()
      ..color = AppTheme.gridLine.withValues(alpha: 0.3)
      ..strokeWidth = 0.3;

    for (int c = 0; c <= gridColumns; c++) {
      canvas.drawLine(
        Offset(c * cellW, 0),
        Offset(c * cellW, size.height),
        linePaint,
      );
    }
    for (int r = 0; r <= gridRows; r++) {
      canvas.drawLine(
        Offset(0, r * cellH),
        Offset(size.width, r * cellH),
        linePaint,
      );
    }
  }

  Color _shadeColor(Color c, double factor) {
    return Color.fromARGB(
      c.alpha,
      (c.red * factor).clamp(0, 255).toInt(),
      (c.green * factor).clamp(0, 255).toInt(),
      (c.blue * factor).clamp(0, 255).toInt(),
    );
  }

  void _drawSandGrains(Canvas canvas, double grainW, double grainH) {
    final buffer = engine.sandGrid.currentBuffer;
    final cols = engine.sandGrid.cols;
    
    final colorList = GameThemes.getTheme(
      GameThemes.classicId,
    ).pieceColors;
    
    // Massive GC optimization: Pre-allocate Paint objects outside the 60fps loop
    final paints = colorList.map((c) {
      return [
        Paint()..color = _shadeColor(c, 0.7),
        Paint()..color = _shadeColor(c, 0.85),
        Paint()..color = c,
        Paint()..color = _shadeColor(c, 1.15),
        Paint()..color = _shadeColor(c, 1.3),
      ];
    }).toList();

    for (int i = 0; i < buffer.length; i++) {
      final grain = buffer[i];
      if (grain == null) continue;

      final r = i ~/ cols;
      final c = i % cols;
      final rect = Rect.fromLTWH(
        c * grainW,
        r * grainH,
        grainW + 0.5, // slight overlap to prevent seams
        grainH + 0.5,
      );

      final colorPaints = paints[grain.colorIndex % paints.length];
      canvas.drawRect(rect, colorPaints[grain.shadeIndex % colorPaints.length]);
    }
  }

  void _drawActivePiece(Canvas canvas, double cellW, double cellH) {
    final piece = engine.activePiece;
    if (piece == null) return;

    final colorList = GameThemes.getTheme(
      GameThemes.classicId,
    ).pieceColors;
    final color = colorList[piece.colorIndex % colorList.length];
    
    // Allocate paints once
    final paint = Paint()..color = color;
    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final cell in piece.absoluteCells) {
      final rect = Rect.fromLTWH(
        cell.col * cellW + 1,
        cell.row * cellH + 1,
        cellW - 2,
        cellH - 2,
      );
      // Fast path: drawRect instead of drawRRect for active piece in Arena Mode
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, highlight);
    }
  }

  void _drawBridgeFlash(Canvas canvas, double grainW, double grainH) {
    if (engine.bridgeAnimations.isEmpty) return;

    final cols = engine.sandGrid.cols;

    for (final anim in engine.bridgeAnimations) {
      final progress = (anim.timer / 0.5).clamp(0.0, 1.0);
      final flashPaint = Paint()
        ..color = Colors.white.withValues(alpha: progress);
      final colorList = GameThemes.getTheme(
        GameThemes.classicId,
      ).pieceColors;
      final paint = Paint()
        ..color = colorList[anim.colorIndex % colorList.length].withValues(
          alpha: progress * 0.8,
        )
        ..style = PaintingStyle.fill;

      for (final idx in anim.indices) {
        final r = idx ~/ cols;
        final c = idx % cols;

        final cx = c * grainW + grainW / 2;
        final cy = r * grainH + grainH / 2;
        final radius = grainW * (1.5 - progress);

        canvas.drawCircle(Offset(cx, cy), radius, paint);

        canvas.drawRect(
          Rect.fromLTWH(c * grainW, r * grainH, grainW + 0.5, grainH + 0.5),
          flashPaint,
        );
      }
    }
  }

  void _drawHardDropTrails(Canvas canvas, double cellW, double cellH) {
    for (final trail in engine.hardDropTrails) {
      final progress = (trail.timer / 0.3).clamp(0.0, 1.0);
      if (progress <= 0) continue;

      final colorList = GameThemes.getTheme(
        GameThemes.classicId,
      ).pieceColors;
      final paint = Paint()
        ..color = colorList[trail.colorIndex % colorList.length].withValues(
          alpha: progress * 0.4,
        )
        ..style = PaintingStyle.fill;

      final rect = Rect.fromLTRB(
        trail.col * cellW,
        trail.startRow * cellH,
        (trail.col + 1) * cellW,
        (trail.endRow + 1) * cellH,
      );

      canvas.drawRect(rect, paint);
    }
  }

  void _drawFloatingTexts(Canvas canvas, Size size) {
    if (engine.floatingTexts.isEmpty) return;
    for (final text in engine.floatingTexts) {
      final progress = text.timer / 2.0; // Assume max 2.0s
      final alpha = (progress * 2).clamp(0.0, 1.0);
      final dy = size.height * 0.4 - (1.0 - progress) * 80;

      final textStyle = TextStyle(
        color: Color(text.colorArgb).withValues(alpha: alpha),
        fontSize: 24,
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: alpha),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
          Shadow(
            color: Color(text.colorArgb).withValues(alpha: alpha * 0.5),
            blurRadius: 10,
          ),
        ],
      );

      final textSpan = TextSpan(text: text.text, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset((size.width - textPainter.width) / 2, dy),
      );
    }
  }

  @override
  bool shouldRepaint(covariant ArenaPainter oldDelegate) => true;
}
