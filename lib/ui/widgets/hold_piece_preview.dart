import 'package:flutter/material.dart';
import 'package:cubix_blast/ui/widgets/block_painter_utils.dart';
import 'package:cubix_blast/core/piece.dart';
import 'package:cubix_blast/theme/game_themes.dart';
import 'package:cubix_blast/core/score_manager.dart';
import 'dart:ui';

/// Shows a mini preview of the held piece.
class HoldPiecePreview extends StatelessWidget {
  const HoldPiecePreview({
    super.key,
    required this.piece,
    required this.canHold,
  });

  final CubixPiece? piece;
  final bool canHold;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFF0D1420).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: canHold
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                  : Colors.white24,
              width: 1,
            ),
          ),
          child: CustomPaint(painter: _HoldPiecePainter(piece, canHold)),
        ),
      ),
    );
  }
}

class _HoldPiecePainter extends CustomPainter {
  _HoldPiecePainter(this.piece, this.canHold);
  final CubixPiece? piece;
  final bool canHold;

  @override
  void paint(Canvas canvas, Size size) {
    if (piece == null) return;

    final cells = piece!.cells;
    if (cells.isEmpty) return;

    // Find bounding box
    int minR = cells[0].row, maxR = cells[0].row;
    int minC = cells[0].col, maxC = cells[0].col;
    for (final c in cells) {
      if (c.row < minR) minR = c.row;
      if (c.row > maxR) maxR = c.row;
      if (c.col < minC) minC = c.col;
      if (c.col > maxC) maxC = c.col;
    }

    final pieceW = maxC - minC + 1;
    final pieceH = maxR - minR + 1;
    final cellSize = (size.shortestSide - 20) / 4; // max 4 cells wide
    final offsetX = (size.width - pieceW * cellSize) / 2;
    final offsetY = (size.height - pieceH * cellSize) / 2;

    final colorList = GameThemes.getTheme(
      ScoreManager.currentTheme,
    ).pieceColors;
    Color color = colorList[piece!.colorIndex % colorList.length];
    if (!canHold) {
      // Gray out the piece if it cannot be held
      color = Colors.grey.withValues(alpha: 0.5);
    }
    final paint = Paint()..color = color;

    for (final cell in cells) {
      final rect = Rect.fromLTWH(
        offsetX + (cell.col - minC) * cellSize + 1,
        offsetY + (cell.row - minR) * cellSize + 1,
        cellSize - 2,
        cellSize - 2,
      );
      BlockPainterUtils.drawBlock(
        canvas: canvas,
        rect: rect,
        color: color,
        style: GameThemes.getTheme(ScoreManager.currentTheme).pieceStyle,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HoldPiecePainter old) =>
      old.piece != piece || old.canHold != canHold;
}
