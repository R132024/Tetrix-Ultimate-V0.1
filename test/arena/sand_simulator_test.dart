import 'package:flutter_test/flutter_test.dart';
import 'package:cubix_blast/arena/logic/sand_grid.dart';
import 'package:cubix_blast/arena/logic/sand_simulator.dart';

void main() {
  group('SandSimulator', () {
    late SandSimulator sim;

    setUp(() {
      sim = SandSimulator(seed: 42);
    });

    test('grain falls down when space below is empty', () {
      final grid = SandGrid(cols: 5, rows: 5);
      grid.setCell(0, 2, const SandGrain(0, 0));

      sim.step(grid);

      expect(grid.getCell(0, 2), null);
      expect(grid.getCell(1, 2), isNotNull);
      expect(grid.getCell(1, 2)!.colorIndex, 0);
    });

    test('grain stays when at bottom', () {
      final grid = SandGrid(cols: 5, rows: 5);
      grid.setCell(4, 2, const SandGrain(1, 0));

      sim.step(grid);

      expect(grid.getCell(4, 2), isNotNull);
      expect(grid.getCell(4, 2)!.colorIndex, 1);
    });

    test('grain slides diagonally when blocked below', () {
      final grid = SandGrid(cols: 5, rows: 5);
      // Place grain above a blocker at the bottom
      grid.setCell(3, 2, const SandGrain(0, 0));
      grid.setCell(4, 2, const SandGrain(1, 0)); // Blocker at very bottom

      sim.step(grid);

      // Grain should have moved diagonally (to 4,1 or 4,3)
      final movedLeft = grid.getCell(4, 1);
      final movedRight = grid.getCell(4, 3);
      expect(movedLeft != null || movedRight != null, true, reason: 'Grain should have moved left or right');
      expect(grid.getCell(3, 2), null);
    });

    test('step returns true when grains move', () {
      final grid = SandGrid(cols: 5, rows: 5);
      grid.setCell(0, 2, const SandGrain(0, 0));

      final moved = sim.step(grid);
      expect(moved, true);
    });

    test('step returns false when no grains move', () {
      final grid = SandGrid(cols: 5, rows: 5);
      grid.setCell(4, 2, const SandGrain(0, 0));

      final moved = sim.step(grid);
      expect(moved, false);
    });

    test('multiple grains settle over time', () {
      final grid = SandGrid(cols: 3, rows: 10);
      // Place 3 grains at the top
      grid.setCell(0, 0, const SandGrain(0, 0));
      grid.setCell(0, 1, const SandGrain(1, 0));
      grid.setCell(0, 2, const SandGrain(2, 0));

      // Run enough steps for them to settle at the bottom
      for (int i = 0; i < 20; i++) {
        sim.step(grid);
      }

      // All grains should be at or near the bottom
      expect(grid.getCell(9, 0), isNotNull);
      expect(grid.getCell(9, 1), isNotNull);
      expect(grid.getCell(9, 2), isNotNull);
    });
  });
}
