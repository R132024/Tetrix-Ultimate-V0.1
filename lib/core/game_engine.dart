/// Shared game state model and abstract engine contract.
///
/// Pure Dart – no Flutter imports.
library;

import 'piece.dart';

/// Running status of a game session.
enum GameStatus { ready, playing, paused, gameOver, roundCleared }

class GameState {
  const GameState({
    this.status = GameStatus.ready,
    this.score = 0,
    this.level = 1,
    this.linesCleared = 0,
    this.elapsedSeconds = 0.0,
  });

  final GameStatus status;
  final int score;
  final int level;
  final int linesCleared;
  final double elapsedSeconds;

  GameState copyWith({
    GameStatus? status,
    int? score,
    int? level,
    int? linesCleared,
    double? elapsedSeconds,
  }) => GameState(
    status: status ?? this.status,
    score: score ?? this.score,
    level: level ?? this.level,
    linesCleared: linesCleared ?? this.linesCleared,
    elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
  );
}

/// The contract that both ClassicEngine and ArenaEngine implement.
///
/// The UI layer interacts **only** through this interface, making
/// the game loop and input handling mode-agnostic.
class FloatingText {
  FloatingText(this.text, this.timer, this.colorArgb);
  final String text;
  double timer;
  final int colorArgb;
}

class HardDropTrail {
  HardDropTrail(
    this.col,
    this.startRow,
    this.endRow,
    this.colorIndex,
    this.timer,
  );
  final int col;
  final int startRow;
  final int endRow;
  final int colorIndex;
  double timer;
}

abstract class GameEngine {
  /// Current game state (score, level, status).
  GameState get state;

  /// The piece currently under player control (null between spawns).
  CubixPiece? get activePiece;

  /// The next piece that will spawn.
  CubixPiece? get nextPiece;

  /// The piece currently held in reserve.
  CubixPiece? get heldPiece;

  /// True if the player is allowed to hold a piece this turn.
  bool get canHold;

  /// Screen shake timer (for hard drops).
  double get shakeTimer;

  /// List of hard drop trails.
  List<HardDropTrail> get hardDropTrails;

  /// List of floating text popups (combos, lines cleared).
  List<FloatingText> get floatingTexts;

  /// High score for the current mode.
  int get highScore;

  /// Timer for the 3-2-1 countdown after reviving.
  double get reviveCountdown;

  // ─── Lifecycle ──────────────────────────────────────────────

  /// Advance the simulation by [dt] seconds.
  void update(double dt);

  /// Start or restart the game from scratch.
  void reset({int initialLevel = 1});

  /// Forces the game to end (used when opponent wins in multiplayer).
  void forceGameOver();

  /// Toggle pause / resume.
  void togglePause();

  /// Revives the player by clearing some lines and setting status back to playing.
  void revive();

  // ─── Player input ───────────────────────────────────────────

  void moveLeft();
  void moveRight();
  void rotateClockwise();
  void softDrop();
  void hardDrop();
  void holdPiece();
  
  /// Toggle fast dropping mode (soft drop acceleration).
  void setFastDrop(bool enabled);

  /// Callback when garbage is sent to the opponent.
  void Function(int damage)? get onGarbageSent;
  set onGarbageSent(void Function(int damage)? callback);

  /// Pending garbage waiting to be inserted.
  int get pendingGarbage;

  /// Receive garbage from the opponent.
  void receiveGarbage(int lines);
}
