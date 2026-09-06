import 'package:flutter_test/flutter_test.dart';
import 'package:cubix_blast/core/grid.dart';
import 'package:cubix_blast/core/piece.dart';

void main() {
  group('Grid', () {
    test('initializes empty', () {
      final grid = Grid(5, 5);
      for (int r = 0; r < 5; r++) {
        for (int c = 0; c < 5; c++) {
          expect(grid.getCell(r, c), null);
        }
      }
    });

    test('setCell and getCell work correctly', () {
      final grid = Grid(5, 5);
      grid.setCell(2, 3, 1);
      expect(grid.getCell(2, 3), 1);
      expect(grid.getCell(0, 0), null);
    });

    test('inBounds checks correctly', () {
      final grid = Grid(5, 5);
      expect(grid.inBounds(0, 0), true);
      expect(grid.inBounds(4, 4), true);
      expect(grid.inBounds(-1, 0), false);
      expect(grid.inBounds(0, 5), false);
      expect(grid.inBounds(5, 0), false);
    });

    test('isEmpty returns true for empty in-bounds cell', () {
      final grid = Grid(5, 5);
      expect(grid.isEmpty(0, 0), true);
      grid.setCell(0, 0, 1);
      expect(grid.isEmpty(0, 0), false);
      expect(grid.isEmpty(-1, 0), false); // out of bounds
    });

    test('collides detects wall collision', () {
      final grid = Grid(10, 10);
      const piece = CubixPiece(
        shape: CubixShape.shaftI,
        colorIndex: 0,
        row: 0,
        col: 8, // Will extend beyond right wall
      );
      expect(grid.collides(piece), true);
    });

    test('collides detects block collision', () {
      final grid = Grid(20, 10);
      grid.setCell(5, 3, 2);
      const piece = CubixPiece(
        shape: CubixShape.boxO,
        colorIndex: 1,
        row: 4,
        col: 3,
      );
      // O-piece at (4,3) has cells at (4,3), (4,4), (5,3), (5,4)
      // (5,3) is occupied → collision
      expect(grid.collides(piece), true);
    });

    test('lockPiece stamps piece onto grid', () {
      final grid = Grid(20, 10);
      const piece = CubixPiece(
        shape: CubixShape.boxO,
        colorIndex: 1,
        row: 18,
        col: 4,
      );
      grid.lockPiece(piece);
      expect(grid.getCell(18, 4), 1);
      expect(grid.getCell(18, 5), 1);
      expect(grid.getCell(19, 4), 1);
      expect(grid.getCell(19, 5), 1);
    });

    test('isRowFull detects complete rows', () {
      final grid = Grid(5, 3);
      // Fill row 4 completely
      for (int c = 0; c < 3; c++) {
        grid.setCell(4, c, 0);
      }
      expect(grid.isRowFull(4), true);
      expect(grid.isRowFull(3), false);
    });

    test('clearRow empties a row', () {
      final grid = Grid(5, 3);
      for (int c = 0; c < 3; c++) {
        grid.setCell(4, c, 0);
      }
      grid.clearRow(4);
      for (int c = 0; c < 3; c++) {
        expect(grid.getCell(4, c), null);
      }
    });

    test('copyRow copies contents', () {
      final grid = Grid(5, 3);
      grid.setCell(2, 0, 1);
      grid.setCell(2, 1, 2);
      grid.setCell(2, 2, 3);
      grid.copyRow(2, 4);
      expect(grid.getCell(4, 0), 1);
      expect(grid.getCell(4, 1), 2);
      expect(grid.getCell(4, 2), 3);
    });

    test('clear empties entire grid', () {
      final grid = Grid(3, 3);
      grid.setCell(0, 0, 1);
      grid.setCell(1, 1, 2);
      grid.setCell(2, 2, 3);
      grid.clear();
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
          expect(grid.getCell(r, c), null);
        }
      }
    });
  });
}
