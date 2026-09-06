import 'package:flutter_test/flutter_test.dart';
import 'package:cubix_blast/classic/logic/line_clearer.dart';
import 'package:cubix_blast/core/grid.dart';

void main() {
  group('LineClearer', () {
    const clearer = LineClearer();

    test('returns empty result when no rows are full', () {
      final grid = Grid(5, 3);
      grid.setCell(4, 0, 1);
      grid.setCell(4, 1, 1);
      // Row 4 is missing col 2
      final result = clearer.clearFullRows(grid);
      expect(result.any, false);
      expect(result.count, 0);
    });

    test('clears a single full row', () {
      final grid = Grid(5, 3);
      for (int c = 0; c < 3; c++) {
        grid.setCell(4, c, 1);
      }
      final result = clearer.clearFullRows(grid);
      expect(result.any, true);
      expect(result.count, 1);
      // Row should now be empty
      for (int c = 0; c < 3; c++) {
        expect(grid.getCell(4, c), null);
      }
    });

    test('collapses rows above cleared row', () {
      final grid = Grid(5, 3);
      // Put blocks on row 3
      grid.setCell(3, 0, 2);
      grid.setCell(3, 1, 3);
      // Fill row 4 completely
      for (int c = 0; c < 3; c++) {
        grid.setCell(4, c, 1);
      }

      clearer.clearFullRows(grid);

      // Row 3's blocks should have moved down to row 4
      expect(grid.getCell(4, 0), 2);
      expect(grid.getCell(4, 1), 3);
      expect(grid.getCell(4, 2), null);
      // Row 3 should now be empty
      expect(grid.getCell(3, 0), null);
    });

    test('clears multiple rows', () {
      final grid = Grid(5, 3);
      // Fill rows 3 and 4
      for (int c = 0; c < 3; c++) {
        grid.setCell(3, c, 1);
        grid.setCell(4, c, 2);
      }
      final result = clearer.clearFullRows(grid);
      expect(result.count, 2);
    });

    test('clears non-contiguous rows', () {
      final grid = Grid(5, 3);
      // Row 1
      grid.setCell(1, 0, 8);
      // Row 2 is full
      for (int c = 0; c < 3; c++) {
        grid.setCell(2, c, 1);
      }
      // Row 3
      grid.setCell(3, 0, 9);
      // Row 4 is full
      for (int c = 0; c < 3; c++) {
        grid.setCell(4, c, 2);
      }

      final result = clearer.clearFullRows(grid);
      expect(result.count, 2);

      // What was on row 3 should be on row 4
      expect(grid.getCell(4, 0), 9);
      // What was on row 1 should be on row 3
      expect(grid.getCell(3, 0), 8);
      // Row 1 and 2 should be empty
      expect(grid.getCell(2, 0), null);
      expect(grid.getCell(1, 0), null);
    });
  });
}
