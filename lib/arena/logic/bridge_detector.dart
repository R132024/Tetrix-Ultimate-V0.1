/// Bridge detector for Arena mode.
///
/// Detects when sand grains of the same color form a connected path
/// from the left wall to the right wall (a "bridge").
/// Uses BFS flood-fill.
///
/// Pure Dart – no Flutter imports.
library;

import 'dart:collection';
import 'sand_grid.dart';

/// Result of a bridge detection scan.
class BridgeResult {
  const BridgeResult({
    required this.found,
    this.colorIndex = -1,
    this.connectedIndices = const {},
  });

  /// Whether a bridge was found.
  final bool found;

  /// The color of the bridge.
  final int colorIndex;

  /// Flat indices of all grains in the connected bridge.
  final Set<int> connectedIndices;

  static const none = BridgeResult(found: false);
}

/// Scans the sand grid for same-color bridges connecting left ↔ right walls.
class BridgeDetector {
  const BridgeDetector();

  /// Check for any color bridge. Returns the first one found, or [BridgeResult.none].
  BridgeResult detect(SandGrid grid) {
    // Collect all colors present on the left wall
    final leftWallColors = <int>{};
    for (int r = 0; r < grid.rows; r++) {
      final grain = grid.getCell(r, 0);
      if (grain != null) {
        leftWallColors.add(grain.colorIndex);
      }
    }

    // For each candidate color, BFS from left-wall grains of that color
    for (final color in leftWallColors) {
      final result = _bfsForColor(grid, color);
      if (result.found) return result;
    }

    return BridgeResult.none;
  }

  BridgeResult _bfsForColor(SandGrid grid, int colorIndex) {
    final visited = <int>{};
    final queue = Queue<int>();
    bool reachedRight = false;

    // Seed BFS with all left-wall grains of this color
    for (int r = 0; r < grid.rows; r++) {
      final grain = grid.getCell(r, 0);
      if (grain != null && grain.colorIndex == colorIndex) {
        final idx = grid.flatIndex(r, 0);
        if (visited.add(idx)) {
          queue.add(idx);
        }
      }
    }

    // BFS: 4-directional neighbors
    while (queue.isNotEmpty) {
      final idx = queue.removeFirst();
      final r = idx ~/ grid.cols;
      final c = idx % grid.cols;

      if (c == grid.cols - 1) {
        reachedRight = true;
        // Don't break — we want to collect ALL connected grains for removal
      }

      for (final (dr, dc) in [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
        final nr = r + dr;
        final nc = c + dc;
        if (!grid.inBounds(nr, nc)) continue;
        final neighbor = grid.getCell(nr, nc);
        if (neighbor == null || neighbor.colorIndex != colorIndex) continue;
        final nIdx = grid.flatIndex(nr, nc);
        if (visited.add(nIdx)) {
          queue.add(nIdx);
        }
      }
    }

    if (reachedRight) {
      return BridgeResult(
        found: true,
        colorIndex: colorIndex,
        connectedIndices: visited,
      );
    }

    return BridgeResult.none;
  }
}
