/// 7-bag randomizer for piece generation.
///
/// Pure Dart – no Flutter imports.
library;

import 'dart:math';
import 'piece.dart';

/// Generates [CubixPiece] instances using the 7-bag randomizer algorithm.
///
/// All 7 shapes are dealt once (in shuffled order) before any shape repeats.
/// This prevents long droughts of any single shape.
class PieceFactory {
  PieceFactory({int? seed, this.maxColors}) : _rng = Random(seed);

  final Random _rng;
  final int? maxColors;
  final List<CubixShape> _bag = [];

  /// Returns the next piece with its correct color and spawn position.
  ///
  /// [spawnCol] defaults to center of a standard grid.
  CubixPiece next({int spawnRow = 0, int spawnCol = 3}) {
    if (_bag.isEmpty) {
      _bag.addAll(CubixShape.values);
      _bag.shuffle(_rng);
    }
    final shape = _bag.removeLast();
    int colorIndex = shapeColorIndex[shape]!;
    if (maxColors != null) {
      colorIndex = colorIndex % maxColors!;
    }

    return CubixPiece(
      shape: shape,
      colorIndex: colorIndex,
      row: spawnRow,
      col: spawnCol,
    );
  }

  /// Peek at the next piece without consuming it.
  CubixPiece peekNext({int spawnRow = 0, int spawnCol = 0}) {
    if (_bag.isEmpty) {
      _bag.addAll(CubixShape.values);
      _bag.shuffle(_rng);
    }
    final shape = _bag.last;
    int colorIndex = shapeColorIndex[shape]!;
    if (maxColors != null) {
      colorIndex = colorIndex % maxColors!;
    }

    return CubixPiece(
      shape: shape,
      colorIndex: colorIndex,
      row: spawnRow,
      col: spawnCol,
    );
  }

  /// Reset the bag (e.g., on game restart).
  void reset() => _bag.clear();
}
