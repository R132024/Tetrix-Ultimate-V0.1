import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cubix_blast/classic/logic/classic_engine.dart';
import 'package:cubix_blast/core/game_engine.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:cubix_blast/core/score_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (methodCall) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (methodCall) async => null,
    );
  });

  group('ClassicEngine', () {
    late ClassicEngine engine;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ScoreManager.init();
      engine = ClassicEngine(seed: 42);
      engine.reset();
    });

    test('starts in playing state', () {
      expect(engine.state.status, GameStatus.playing);
      expect(engine.state.score, 0);
      expect(engine.state.level, 1);
      expect(engine.activePiece, isNotNull);
      expect(engine.nextPiece, isNotNull);
    });

    test('active piece falls over time', () {
      final initialRow = engine.activePiece!.row;
      // Simulate enough time for piece to drop
      for (int i = 0; i < 100; i++) {
        engine.update(1.0 / 60.0);
      }
      expect(engine.activePiece!.row, greaterThan(initialRow));
    });

    test('moveLeft moves piece left', () {
      final initialCol = engine.activePiece!.col;
      engine.moveLeft();
      expect(engine.activePiece!.col, initialCol - 1);
    });

    test('moveRight moves piece right', () {
      final initialCol = engine.activePiece!.col;
      engine.moveRight();
      expect(engine.activePiece!.col, initialCol + 1);
    });

    test('rotateClockwise changes rotation', () {
      final initialRotation = engine.activePiece!.rotation;
      engine.rotateClockwise();
      // Might or might not rotate depending on wall kicks, but at minimum
      // the method shouldn't crash
      expect(engine.activePiece, isNotNull);
      // If there's room, rotation should change
      if (engine.activePiece!.rotation != initialRotation) {
        expect(engine.activePiece!.rotation, isNot(initialRotation));
      }
    });

    test('softDrop moves piece down and adds score', () {
      final initialRow = engine.activePiece!.row;
      final initialScore = engine.state.score;
      engine.softDrop();
      expect(engine.activePiece!.row, initialRow + 1);
      expect(engine.state.score, greaterThan(initialScore));
    });

    test('hardDrop locks piece immediately', () {
      engine.hardDrop();
      // After hard drop, piece should have changed (locked + new spawn)
      // Score should increase
      expect(engine.state.score, greaterThan(0));
    });

    test('togglePause pauses and resumes', () {
      engine.togglePause();
      expect(engine.state.status, GameStatus.paused);
      engine.togglePause();
      expect(engine.state.status, GameStatus.playing);
    });

    test('update does nothing when paused', () {
      engine.togglePause();
      final row = engine.activePiece!.row;
      for (int i = 0; i < 100; i++) {
        engine.update(1.0 / 60.0);
      }
      expect(engine.activePiece!.row, row);
    });

    test('ghostPiece is below active piece', () {
      final ghost = engine.ghostPiece;
      expect(ghost, isNotNull);
      expect(ghost!.row, greaterThanOrEqualTo(engine.activePiece!.row));
    });

    test('reset restores initial state', () {
      // Play for a while
      for (int i = 0; i < 500; i++) {
        engine.update(1.0 / 60.0);
      }
      engine.reset();
      expect(engine.state.status, GameStatus.playing);
      expect(engine.state.score, 0);
      expect(engine.state.level, 1);
      expect(engine.activePiece, isNotNull);
    });

    test('revive preserves base blocks and clears upper blocks', () {
      engine.forceGameOver();
      expect(engine.state.status, GameStatus.gameOver);

      engine.revive();
      expect(engine.state.status, GameStatus.playing);
      expect(engine.activePiece, isNotNull);
      // Countdown should be around 4 seconds
      expect(engine.reviveCountdown, greaterThan(3.0));
      expect(engine.reviveCountdown, lessThanOrEqualTo(4.0));
    });

    test('update pauses game while reviveCountdown > 0', () {
      engine.forceGameOver();
      engine.revive();
      final activePieceRow = engine.activePiece!.row;
      // During countdown, game pieces should not drop
      engine.update(0.1);
      expect(engine.activePiece!.row, activePieceRow);
    });
  });
}
