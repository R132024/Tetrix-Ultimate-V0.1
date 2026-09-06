/// Cellular automaton simulator for sand physics.
///
/// Implements falling-sand rules: gravity, lateral spread, settling.
/// Uses double-buffer approach for consistent updates.
///
/// Pure Dart – no Flutter imports.
library;

import 'dart:math';
import 'sand_grid.dart';

class SandSimulator {
  SandSimulator({int? seed, this.diagonalSlideProbability = 0.3}) : _rng = Random(seed);

  final Random _rng;
  final double diagonalSlideProbability;
  int _frameCount = 0;

  /// Run one simulation step on the grid.
  ///
  /// Returns `true` if any grain moved (simulation is active).
  bool step(SandGrid grid) {
    _frameCount++;
    grid.prepareNextBuffer();
    bool anyMoved = false;

    // Alternate scan direction each frame to prevent bias
    final leftToRight = _frameCount.isEven;

    // Scan bottom-up (so grains below are already processed)
    for (int r = grid.rows - 2; r >= 0; r--) {
      final colStart = leftToRight ? 0 : grid.cols - 1;
      final colEnd = leftToRight ? grid.cols : -1;
      final colStep = leftToRight ? 1 : -1;

      for (int c = colStart; c != colEnd; c += colStep) {
        final grain = grid.getCell(r, c);
        if (grain == null) continue;

        // Check if this grain has already been moved by another grain
        // in this step (it was overwritten in the next buffer)
        if (grid.getNext(r, c) != grain) continue;

        // Try to fall straight down
        if (grid.isNextEmpty(r + 1, c)) {
          grid.setNext(r + 1, c, grain);
          grid.setNext(r, c, null);
          anyMoved = true;
          continue;
        }

        // Aplicar fricción / ángulo de reposo:
        // Si el número aleatorio es mayor que la probabilidad, la partícula se detiene en este frame.
        if (_rng.nextDouble() > diagonalSlideProbability) {
          continue;
        }

        // Try diagonal: randomize left/right priority (50/50)
        final tryLeftFirst = _rng.nextBool();
        final d1 = tryLeftFirst ? -1 : 1;
        final d2 = tryLeftFirst ? 1 : -1;

        if (_tryDiagonal(grid, r, c, d1, grain)) {
          anyMoved = true;
          continue;
        }
        if (_tryDiagonal(grid, r, c, d2, grain)) {
          anyMoved = true;
          continue;
        }

        // Grain stays put (already in next buffer from prepareNextBuffer)
      }
    }

    grid.swapBuffers();
    grid.hasActivity = anyMoved;
    return anyMoved;
  }

  bool _tryDiagonal(SandGrid grid, int r, int c, int dc, SandGrain grain) {
    final newC = c + dc;
    // Require the cell directly below the diagonal and the cell to the side to be empty
    if (grid.inBounds(r + 1, newC) &&
        grid.isNextEmpty(r + 1, newC) &&
        grid.isNextEmpty(r, newC)) {
      grid.setNext(r + 1, newC, grain);
      grid.setNext(r, c, null);
      return true;
    }
    return false;
  }
}
