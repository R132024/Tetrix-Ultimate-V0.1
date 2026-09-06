import 'package:flutter_test/flutter_test.dart';
import 'package:cubix_blast/core/piece.dart';

void main() {
  group('CubixPiece', () {
    test('creates piece with correct defaults', () {
      const piece = CubixPiece(shape: CubixShape.shaftI, colorIndex: 0);
      expect(piece.row, 0);
      expect(piece.col, 0);
      expect(piece.rotation, Rotation.r0);
    });

    test('moved returns new piece with offset position', () {
      const piece = CubixPiece(shape: CubixShape.teeT, colorIndex: 2, row: 5, col: 3);
      final moved = piece.moved(1, -1);
      expect(moved.row, 6);
      expect(moved.col, 2);
      expect(moved.shape, CubixShape.teeT);
      expect(moved.colorIndex, 2);
    });

    test('rotated returns new piece with updated rotation', () {
      const piece = CubixPiece(shape: CubixShape.hookJ, colorIndex: 5);
      final rotated = piece.rotated(Rotation.r90);
      expect(rotated.rotation, Rotation.r90);
      expect(rotated.row, piece.row);
      expect(rotated.col, piece.col);
    });

    test('nextRotation wraps around', () {
      const piece = CubixPiece(shape: CubixShape.skewS, colorIndex: 3, rotation: Rotation.r270);
      expect(piece.nextRotation, Rotation.r0);
    });

    test('cells returns correct offsets for I-piece r0', () {
      const piece = CubixPiece(shape: CubixShape.shaftI, colorIndex: 0);
      final cells = piece.cells;
      expect(cells.length, 4);
      // I-piece r0 is horizontal on row 1
      expect(cells, contains(const Offset2D(1, 0)));
      expect(cells, contains(const Offset2D(1, 1)));
      expect(cells, contains(const Offset2D(1, 2)));
      expect(cells, contains(const Offset2D(1, 3)));
    });

    test('absoluteCells adds piece position to offsets', () {
      const piece = CubixPiece(
        shape: CubixShape.boxO,
        colorIndex: 1,
        row: 5,
        col: 4,
      );
      final cells = piece.absoluteCells;
      expect(cells, contains(const Offset2D(5, 4)));
      expect(cells, contains(const Offset2D(5, 5)));
      expect(cells, contains(const Offset2D(6, 4)));
      expect(cells, contains(const Offset2D(6, 5)));
    });

    test('O-piece has same cells in all rotations', () {
      const piece = CubixPiece(shape: CubixShape.boxO, colorIndex: 1);
      final r0 = piece.cells;
      final r90 = piece.rotated(Rotation.r90).cells;
      final r180 = piece.rotated(Rotation.r180).cells;
      final r270 = piece.rotated(Rotation.r270).cells;
      expect(r0, r90);
      expect(r90, r180);
      expect(r180, r270);
    });
  });

  group('Offset2D', () {
    test('equality works', () {
      expect(const Offset2D(1, 2), const Offset2D(1, 2));
      expect(const Offset2D(1, 2), isNot(const Offset2D(2, 1)));
    });
  });
}
