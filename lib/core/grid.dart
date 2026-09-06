/// Generic 2D grid data structure with collision detection.
///
/// Pure Dart – no Flutter imports.
library;

import 'piece.dart';

/// A mutable 2D grid of nullable integers.
///
/// `null` = empty cell, `int` = color index of the block occupying the cell.
class Grid {
  Grid(this.rows, this.cols) : _cells = List.filled(rows * cols, null);

  Grid.from(Grid other)
    : rows = other.rows,
      cols = other.cols,
      _cells = List<int?>.from(other._cells);

  final int rows;
  final int cols;
  final List<int?> _cells;

  // ─── Cell access ──────────────────────────────────────────────

  int? getCell(int row, int col) {
    if (!inBounds(row, col)) return null;
    return _cells[row * cols + col];
  }

  void setCell(int row, int col, int? value) {
    if (inBounds(row, col)) {
      _cells[row * cols + col] = value;
    }
  }

  /// Whether the coordinate is inside the grid.
  bool inBounds(int row, int col) =>
      row >= 0 && row < rows && col >= 0 && col < cols;

  /// Whether the cell is empty (null) **and** in bounds.
  bool isEmpty(int row, int col) =>
      inBounds(row, col) && getCell(row, col) == null;

  // ─── Piece interaction ────────────────────────────────────────

  /// Returns `true` if placing [piece] at its current position would
  /// collide with existing blocks or go out of bounds.
  bool collides(CubixPiece piece) {
    for (final cell in piece.absoluteCells) {
      if (!inBounds(cell.row, cell.col) ||
          getCell(cell.row, cell.col) != null) {
        return true;
      }
    }
    return false;
  }

  /// Stamps the [piece] onto the grid permanently.
  void lockPiece(CubixPiece piece) {
    for (final cell in piece.absoluteCells) {
      setCell(cell.row, cell.col, piece.colorIndex);
    }
  }

  // ─── Row operations ───────────────────────────────────────────

  /// Returns `true` if every cell in [row] is occupied.
  bool isRowFull(int row) {
    for (int c = 0; c < cols; c++) {
      if (getCell(row, c) == null) return false;
    }
    return true;
  }

  /// Clears [row] by setting every cell to `null`.
  void clearRow(int row) {
    for (int c = 0; c < cols; c++) {
      setCell(row, c, null);
    }
  }

  /// Copies contents of [srcRow] into [dstRow].
  void copyRow(int srcRow, int dstRow) {
    for (int c = 0; c < cols; c++) {
      setCell(dstRow, c, getCell(srcRow, c));
    }
  }

  /// Clears the entire grid.
  void clear() => _cells.fillRange(0, _cells.length, null);

  /// Shifts rows UP by [count], dropping the top [count] rows.
  /// Fills the bottom [count] rows with garbage blocks (color index 8),
  /// leaving a hole at [holeColumn].
  void insertGarbageLines(int count, int holeColumn) {
    if (count <= 0) return;
    
    // Shift rows UP (row 0 is top, so row 0 becomes row count)
    // Actually, row 0 is top, so row 0 is overwritten by row `count`
    for (int r = 0; r < rows - count; r++) {
      copyRow(r + count, r);
    }
    
    // Fill bottom rows with garbage
    for (int r = rows - count; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (c == holeColumn) {
          setCell(r, c, null); // Hole
        } else {
          setCell(r, c, 8); // 8 = Garbage block color
        }
      }
    }
  }

  /// Checks if inserting [count] rows of garbage would push blocks out of the top of the grid.
  bool checkGarbageGameOver(int count) {
    for (int r = 0; r < count && r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (getCell(r, c) != null) return true;
      }
    }
    return false;
  }

  /// Checks if any block has locked in the top row within the central columns (3 to 6).
  bool checkTopOut() {
    for (int c = 3; c <= 6; c++) {
      if (getCell(0, c) != null) return true;
    }
    return false;
  }

  // ─── Debug ────────────────────────────────────────────────────

  @override
  String toString() {
    final buf = StringBuffer();
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final v = getCell(r, c);
        buf.write(v == null ? '.' : v.toString());
      }
      buf.writeln();
    }
    return buf.toString();
  }
}
