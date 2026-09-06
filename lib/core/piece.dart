/// Piece shapes and rotation data for CubixBlast.
///
/// Pure Dart – no Flutter imports. Each shape is encoded as a list of
/// (row, col) offsets relative to the piece's pivot.
library;

/// The seven standard piece shapes used in CubixBlast.
enum CubixShape { shaftI, boxO, teeT, skewS, skewZ, hookJ, hookL }

/// Rotation states (0°, 90°, 180°, 270°).
enum Rotation { r0, r90, r180, r270 }

/// An immutable snapshot of a game piece: its shape, rotation, position,
/// and color index.
class CubixPiece {
  const CubixPiece({
    required this.shape,
    this.rotation = Rotation.r0,
    this.row = 0,
    this.col = 0,
    required this.colorIndex,
  });

  final CubixShape shape;
  final Rotation rotation;

  /// Grid position of the piece's pivot (top-left of bounding box).
  final int row;
  final int col;

  /// Index into [pieceColors].
  final int colorIndex;

  /// The block offsets for the current rotation.
  List<Offset2D> get cells => _shapeData[shape]![rotation.index];

  /// Absolute grid coordinates for each block.
  List<Offset2D> get absoluteCells =>
      cells.map((c) => Offset2D(row + c.row, col + c.col)).toList();

  // ─── Immutable transforms ──────────────────────────────────────

  CubixPiece moved(int dRow, int dCol) => CubixPiece(
    shape: shape,
    rotation: rotation,
    row: row + dRow,
    col: col + dCol,
    colorIndex: colorIndex,
  );

  CubixPiece rotated(Rotation newRotation) => CubixPiece(
    shape: shape,
    rotation: newRotation,
    row: row,
    col: col,
    colorIndex: colorIndex,
  );

  CubixPiece withPosition(int newRow, int newCol) => CubixPiece(
    shape: shape,
    rotation: rotation,
    row: newRow,
    col: newCol,
    colorIndex: colorIndex,
  );

  Rotation get nextRotation {
    const values = Rotation.values;
    return values[(rotation.index + 1) % values.length];
  }

  Rotation get prevRotation {
    const values = Rotation.values;
    return values[(rotation.index + values.length - 1) % values.length];
  }
}

/// A simple 2D integer offset (no Flutter dependency).
class Offset2D {
  const Offset2D(this.row, this.col);
  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      other is Offset2D && other.row == row && other.col == col;

  @override
  int get hashCode => row.hashCode ^ (col.hashCode << 16);

  @override
  String toString() => '($row, $col)';
}

// ─── Shape Rotation Data ────────────────────────────────────────
// Each shape has 4 rotation states, each defined as a list of Offset2D
// relative to the bounding-box top-left corner.

const Map<CubixShape, List<List<Offset2D>>> _shapeData = {
  // I-piece: 4×1 horizontal ↔ 1×4 vertical
  CubixShape.shaftI: [
    // r0
    [Offset2D(1, 0), Offset2D(1, 1), Offset2D(1, 2), Offset2D(1, 3)],
    // r90
    [Offset2D(0, 2), Offset2D(1, 2), Offset2D(2, 2), Offset2D(3, 2)],
    // r180
    [Offset2D(2, 0), Offset2D(2, 1), Offset2D(2, 2), Offset2D(2, 3)],
    // r270
    [Offset2D(0, 1), Offset2D(1, 1), Offset2D(2, 1), Offset2D(3, 1)],
  ],

  // O-piece: 2×2, same in all rotations
  CubixShape.boxO: [
    [Offset2D(0, 0), Offset2D(0, 1), Offset2D(1, 0), Offset2D(1, 1)],
    [Offset2D(0, 0), Offset2D(0, 1), Offset2D(1, 0), Offset2D(1, 1)],
    [Offset2D(0, 0), Offset2D(0, 1), Offset2D(1, 0), Offset2D(1, 1)],
    [Offset2D(0, 0), Offset2D(0, 1), Offset2D(1, 0), Offset2D(1, 1)],
  ],

  // T-piece
  CubixShape.teeT: [
    [Offset2D(0, 1), Offset2D(1, 0), Offset2D(1, 1), Offset2D(1, 2)],
    [Offset2D(0, 1), Offset2D(1, 1), Offset2D(1, 2), Offset2D(2, 1)],
    [Offset2D(1, 0), Offset2D(1, 1), Offset2D(1, 2), Offset2D(2, 1)],
    [Offset2D(0, 1), Offset2D(1, 0), Offset2D(1, 1), Offset2D(2, 1)],
  ],

  // S-piece
  CubixShape.skewS: [
    [Offset2D(0, 1), Offset2D(0, 2), Offset2D(1, 0), Offset2D(1, 1)],
    [Offset2D(0, 1), Offset2D(1, 1), Offset2D(1, 2), Offset2D(2, 2)],
    [Offset2D(1, 1), Offset2D(1, 2), Offset2D(2, 0), Offset2D(2, 1)],
    [Offset2D(0, 0), Offset2D(1, 0), Offset2D(1, 1), Offset2D(2, 1)],
  ],

  // Z-piece
  CubixShape.skewZ: [
    [Offset2D(0, 0), Offset2D(0, 1), Offset2D(1, 1), Offset2D(1, 2)],
    [Offset2D(0, 2), Offset2D(1, 1), Offset2D(1, 2), Offset2D(2, 1)],
    [Offset2D(1, 0), Offset2D(1, 1), Offset2D(2, 1), Offset2D(2, 2)],
    [Offset2D(0, 1), Offset2D(1, 0), Offset2D(1, 1), Offset2D(2, 0)],
  ],

  // J-piece
  CubixShape.hookJ: [
    [Offset2D(0, 0), Offset2D(1, 0), Offset2D(1, 1), Offset2D(1, 2)],
    [Offset2D(0, 1), Offset2D(0, 2), Offset2D(1, 1), Offset2D(2, 1)],
    [Offset2D(1, 0), Offset2D(1, 1), Offset2D(1, 2), Offset2D(2, 2)],
    [Offset2D(0, 1), Offset2D(1, 1), Offset2D(2, 0), Offset2D(2, 1)],
  ],

  // L-piece
  CubixShape.hookL: [
    [Offset2D(0, 2), Offset2D(1, 0), Offset2D(1, 1), Offset2D(1, 2)],
    [Offset2D(0, 1), Offset2D(1, 1), Offset2D(2, 1), Offset2D(2, 2)],
    [Offset2D(1, 0), Offset2D(1, 1), Offset2D(1, 2), Offset2D(2, 0)],
    [Offset2D(0, 0), Offset2D(0, 1), Offset2D(1, 1), Offset2D(2, 1)],
  ],
};

/// Wall-kick offsets for standard rotation (SRS-style).
/// Maps (fromRotation, toRotation) → list of (dRow, dCol) to try.
/// Uses a simplified SRS wall-kick table.
const Map<CubixShape, Map<String, List<Offset2D>>> wallKickData = {
  // Non-I pieces share one table
  CubixShape.teeT: _standardWallKicks,
  CubixShape.skewS: _standardWallKicks,
  CubixShape.skewZ: _standardWallKicks,
  CubixShape.hookJ: _standardWallKicks,
  CubixShape.hookL: _standardWallKicks,
  // I-piece has its own
  CubixShape.shaftI: _iWallKicks,
  // O-piece doesn't rotate meaningfully
  CubixShape.boxO: {},
};

const Map<String, List<Offset2D>> _standardWallKicks = {
  '0>1': [Offset2D(0, -1), Offset2D(-1, -1), Offset2D(2, 0), Offset2D(2, -1)],
  '1>0': [Offset2D(0, 1), Offset2D(1, 1), Offset2D(-2, 0), Offset2D(-2, 1)],
  '1>2': [Offset2D(0, 1), Offset2D(-1, 1), Offset2D(2, 0), Offset2D(2, 1)],
  '2>1': [Offset2D(0, -1), Offset2D(1, -1), Offset2D(-2, 0), Offset2D(-2, -1)],
  '2>3': [Offset2D(0, 1), Offset2D(-1, 1), Offset2D(2, 0), Offset2D(2, 1)],
  '3>2': [Offset2D(0, -1), Offset2D(1, -1), Offset2D(-2, 0), Offset2D(-2, -1)],
  '3>0': [Offset2D(0, -1), Offset2D(-1, -1), Offset2D(2, 0), Offset2D(2, -1)],
  '0>3': [Offset2D(0, 1), Offset2D(1, 1), Offset2D(-2, 0), Offset2D(-2, 1)],
};

const Map<String, List<Offset2D>> _iWallKicks = {
  '0>1': [Offset2D(0, -2), Offset2D(0, 1), Offset2D(-1, -2), Offset2D(2, 1)],
  '1>0': [Offset2D(0, 2), Offset2D(0, -1), Offset2D(1, 2), Offset2D(-2, -1)],
  '1>2': [Offset2D(0, -1), Offset2D(0, 2), Offset2D(2, -1), Offset2D(-1, 2)],
  '2>1': [Offset2D(0, 1), Offset2D(0, -2), Offset2D(-2, 1), Offset2D(1, -2)],
  '2>3': [Offset2D(0, 2), Offset2D(0, -1), Offset2D(1, 2), Offset2D(-2, -1)],
  '3>2': [Offset2D(0, -2), Offset2D(0, 1), Offset2D(-1, -2), Offset2D(2, 1)],
  '3>0': [Offset2D(0, 1), Offset2D(0, -2), Offset2D(-2, 1), Offset2D(1, -2)],
  '0>3': [Offset2D(0, -1), Offset2D(0, 2), Offset2D(2, -1), Offset2D(-1, 2)],
};

/// Color index for each shape.
const Map<CubixShape, int> shapeColorIndex = {
  CubixShape.shaftI: 0,
  CubixShape.boxO: 1,
  CubixShape.teeT: 2,
  CubixShape.skewS: 3,
  CubixShape.skewZ: 4,
  CubixShape.hookJ: 5,
  CubixShape.hookL: 6,
};
