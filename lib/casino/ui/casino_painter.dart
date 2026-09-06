import 'package:cubix_blast/ui/widgets/block_painter_utils.dart';
import 'package:flutter/material.dart';
import 'package:cubix_blast/core/constants.dart';
import 'package:cubix_blast/casino/logic/casino_engine.dart';
import 'package:cubix_blast/ui/theme/app_theme.dart';
import 'package:cubix_blast/theme/game_themes.dart';
import 'package:cubix_blast/core/score_manager.dart';

/// Renders the Classic mode grid using CustomPainter.
class CasinoPainter extends CustomPainter {
  CasinoPainter({required this.engine, required this.repaint})
    : super(repaint: repaint);

  final CasinoEngine engine;
  final ValueNotifier<int> repaint;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / gridColumns;
    final cellH = size.height / gridRows;

    _drawBackground(canvas, size, cellW, cellH);
    _drawLockedBlocks(canvas, cellW, cellH);
    _drawHardDropTrails(canvas, cellW, cellH);
    _drawGhostPiece(canvas, cellW, cellH);
    _drawActivePiece(canvas, cellW, cellH);
    _drawClearedRowFlash(canvas, size, cellW, cellH);
    engine.particleManager.draw(canvas, size);
    _drawFloatingTexts(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size, double cellW, double cellH) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppTheme.gridBackground,
    );

    final linePaint = Paint()
      ..color = AppTheme.gridLine
      ..strokeWidth = 0.5;

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

  void _drawLockedBlocks(Canvas canvas, double cellW, double cellH) {
    final grid = engine.grid;
    for (int r = 0; r < gridRows; r++) {
      for (int c = 0; c < gridColumns; c++) {
        final colorIndex = grid.getCell(r, c);
        if (colorIndex != null) {
          final colorList = GameThemes.getTheme(
            ScoreManager.currentTheme,
          ).pieceColors;
          _drawBlock(
            canvas,
            r,
            c,
            cellW,
            cellH,
            colorList[colorIndex % colorList.length],
          );
        }
      }
    }
  }

  void _drawGhostPiece(Canvas canvas, double cellW, double cellH) {
    final ghost = engine.ghostPiece;
    if (ghost == null) return;
    for (final cell in ghost.absoluteCells) {
      _drawBlock(
        canvas,
        cell.row,
        cell.col,
        cellW,
        cellH,
        AppTheme.ghostColor,
        isGhost: true,
      );
    }
  }

  void _drawActivePiece(Canvas canvas, double cellW, double cellH) {
    final piece = engine.activePiece;
    if (piece == null) return;
    for (final cell in piece.absoluteCells) {
      final colorList = GameThemes.getTheme(
        ScoreManager.currentTheme,
      ).pieceColors;
      _drawBlock(
        canvas,
        cell.row,
        cell.col,
        cellW,
        cellH,
        colorList[piece.colorIndex % colorList.length],
      );
    }
  }

  void _drawClearedRowFlash(
    Canvas canvas,
    Size size,
    double cellW,
    double cellH,
  ) {
    if (engine.clearedRowTimers.isEmpty) return;

    for (final entry in engine.clearedRowTimers.entries) {
      final row = entry.key;
      final progress = (entry.value / 0.4).clamp(0.0, 1.0);

      // Flash rectangle fading out
      final flashPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8 * progress);
      canvas.drawRect(
        Rect.fromLTWH(0, row * cellH, size.width, cellH),
        flashPaint,
      );

      // Expanding energy line
      final linePaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: progress)
        ..strokeWidth = 4.0 * progress
        ..strokeCap = StrokeCap.round;

      final cy = row * cellH + cellH / 2;
      canvas.drawLine(
        Offset(size.width / 2 * (1.0 - progress), cy),
        Offset(size.width / 2 * (1.0 + progress), cy),
        linePaint,
      );
    }
  }

  void _drawBlock(
    Canvas canvas,
    int row,
    int col,
    double cellW,
    double cellH,
    Color color, {
    bool isGhost = false,
  }) {
    final rect = Rect.fromLTWH(
      col * cellW + 1,
      row * cellH + 1,
      cellW - 2,
      cellH - 2,
    );
    BlockPainterUtils.drawBlock(
      canvas: canvas,
      rect: rect,
      color: color,
      style: GameThemes.getTheme(ScoreManager.currentTheme).pieceStyle,
      isGhost: isGhost,
    );
  }

  void _drawHardDropTrails(Canvas canvas, double cellW, double cellH) {
    for (final trail in engine.hardDropTrails) {
      final progress = (trail.timer / 0.3).clamp(0.0, 1.0);
      if (progress <= 0) continue;

      final colorList = GameThemes.getTheme(
        ScoreManager.currentTheme,
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
  bool shouldRepaint(covariant CasinoPainter oldDelegate) => true;
}
