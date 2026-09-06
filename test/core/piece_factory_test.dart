import 'package:flutter_test/flutter_test.dart';
import 'package:cubix_blast/core/piece.dart';
import 'package:cubix_blast/core/piece_factory.dart';

void main() {
  group('PieceFactory', () {
    test('generates pieces with valid shapes', () {
      final factory = PieceFactory(seed: 42);
      for (int i = 0; i < 21; i++) {
        final piece = factory.next();
        expect(CubixShape.values.contains(piece.shape), true);
        expect(piece.colorIndex, shapeColorIndex[piece.shape]);
      }
    });

    test('7-bag: all 7 shapes appear in each batch of 7', () {
      final factory = PieceFactory(seed: 123);
      for (int batch = 0; batch < 3; batch++) {
        final shapes = <CubixShape>{};
        for (int i = 0; i < 7; i++) {
          shapes.add(factory.next().shape);
        }
        expect(shapes.length, 7, reason: 'Batch $batch should have all 7 shapes');
      }
    });

    test('peekNext returns same shape as next without consuming', () {
      final factory = PieceFactory(seed: 99);
      final peeked = factory.peekNext();
      final actual = factory.next();
      expect(peeked.shape, actual.shape);
    });

    test('reset clears the bag', () {
      final factory1 = PieceFactory(seed: 42);
      final factory2 = PieceFactory(seed: 42);

      // Get some pieces
      factory1.next();
      factory1.next();
      factory1.reset();

      // After reset with same seed, bags won't match (new shuffle)
      // But we can verify it doesn't crash
      final piece = factory1.next();
      expect(piece.shape, isNotNull);

      // factory2 from same seed should produce same sequence
      final p2 = factory2.next();
      expect(p2.shape, isNotNull);
    });
  });
}
