import 'package:flutter_test/flutter_test.dart';
import 'package:cubix_blast/arena/logic/sand_grid.dart';
import 'package:cubix_blast/arena/logic/bridge_detector.dart';

void main() {
  group('BridgeDetector', () {
    const detector = BridgeDetector();

    test('returns none when grid is empty', () {
      final grid = SandGrid(cols: 5, rows: 5);
      final result = detector.detect(grid);
      expect(result.found, false);
    });

    test('returns none when no bridge connects left to right', () {
      final grid = SandGrid(cols: 5, rows: 5);
      // Place grains only on left wall
      grid.setCell(4, 0, const SandGrain(0, 0));
      grid.setCell(3, 0, const SandGrain(0, 0));

      final result = detector.detect(grid);
      expect(result.found, false);
    });

    test('detects a horizontal bridge', () {
      final grid = SandGrid(cols: 5, rows: 5);
      // Create a horizontal bridge of color 0 across row 4
      for (int c = 0; c < 5; c++) {
        grid.setCell(4, c, const SandGrain(0, 0));
      }

      final result = detector.detect(grid);
      expect(result.found, true);
      expect(result.colorIndex, 0);
      expect(result.connectedIndices.length, 5);
    });

    test('detects a zigzag bridge', () {
      final grid = SandGrid(cols: 5, rows: 5);
      // Create a zigzag path of color 1
      grid.setCell(4, 0, const SandGrain(1, 0));
      grid.setCell(3, 0, const SandGrain(1, 0));
      grid.setCell(3, 1, const SandGrain(1, 0));
      grid.setCell(3, 2, const SandGrain(1, 0));
      grid.setCell(4, 2, const SandGrain(1, 0));
      grid.setCell(4, 3, const SandGrain(1, 0));
      grid.setCell(3, 3, const SandGrain(1, 0));
      grid.setCell(3, 4, const SandGrain(1, 0));

      final result = detector.detect(grid);
      expect(result.found, true);
      expect(result.colorIndex, 1);
    });

    test('does not bridge different colors', () {
      final grid = SandGrid(cols: 5, rows: 5);
      // Color 0 on left, color 1 in middle, color 0 on right
      grid.setCell(4, 0, const SandGrain(0, 0));
      grid.setCell(4, 1, const SandGrain(0, 0));
      grid.setCell(4, 2, const SandGrain(1, 0)); // Different color breaks bridge
      grid.setCell(4, 3, const SandGrain(0, 0));
      grid.setCell(4, 4, const SandGrain(0, 0));

      final result = detector.detect(grid);
      expect(result.found, false);
    });

    test('does not detect bridge when there is a hole (gap)', () {
      final grid = SandGrid(cols: 5, rows: 5);
      grid.setCell(4, 0, const SandGrain(0, 0));
      grid.setCell(4, 1, const SandGrain(0, 0));
      // Hole at col 2
      grid.setCell(4, 3, const SandGrain(0, 0));
      grid.setCell(4, 4, const SandGrain(0, 0));

      final result = detector.detect(grid);
      expect(result.found, false);
    });

    test('collects all connected grains in the bridge', () {
      final grid = SandGrid(cols: 3, rows: 3);
      // Fill entire grid with same color
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
          grid.setCell(r, c, const SandGrain(2, 0));
        }
      }

      final result = detector.detect(grid);
      expect(result.found, true);
      expect(result.connectedIndices.length, 9); // All cells connected
    });
  });
}
