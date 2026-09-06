/// Line-clearing logic for Classic mode.
///
/// Pure Dart – no Flutter imports.
library;

import 'package:cubix_blast/core/grid.dart';

/// Result of a line-clear operation.
class LineClearResult {
  const LineClearResult(this.rowsCleared);

  /// Row indices that were cleared (top to bottom order).
  final List<int> rowsCleared;

  int get count => rowsCleared.length;
  bool get any => rowsCleared.isNotEmpty;
}

/// Scans the grid for full rows, clears them, and collapses rows above.
class LineClearer {
  const LineClearer();

  /// Find and clear all full rows. Returns info about what was cleared.
  LineClearResult clearFullRows(Grid grid) {
    final fullRows = <int>[];

    // Scan bottom-up
    for (int r = grid.rows - 1; r >= 0; r--) {
      if (grid.isRowFull(r)) {
        fullRows.add(r);
      }
    }

    if (fullRows.isEmpty) return const LineClearResult([]);

    // Sort top-to-bottom for correct collapse order
    fullRows.sort();

    // Collapse: shift rows down to fill cleared gaps
    _collapse(grid, fullRows);

    return LineClearResult(fullRows);
  }

  void _collapse(Grid grid, List<int> clearedRows) {
    // Work from bottom cleared row upward
    int writeRow = clearedRows.last;

    for (int readRow = clearedRows.last - 1; readRow >= 0; readRow--) {
      if (clearedRows.contains(readRow)) continue;
      grid.copyRow(readRow, writeRow);
      writeRow--;
    }

    // Clear remaining top rows
    for (int r = writeRow; r >= 0; r--) {
      grid.clearRow(r);
    }
  }
}
