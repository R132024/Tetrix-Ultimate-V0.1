/// Arena mode game engine.
///
/// Pieces fall like Classic mode, but upon locking they disintegrate
/// into sand particles governed by a cellular automaton.
/// Lines clear when same-color sand connects left wall → right wall.
///
/// Pure Dart – no Flutter imports.
library;

import 'dart:math';
import 'package:cubix_blast/core/constants.dart';
import 'package:cubix_blast/core/game_engine.dart';
import 'package:cubix_blast/core/grid.dart';
import 'package:cubix_blast/core/piece.dart';
import 'package:cubix_blast/core/piece_factory.dart';
import 'package:cubix_blast/core/score_manager.dart';
import 'package:cubix_blast/core/audio_service.dart';
import 'package:flutter/services.dart';
import 'sand_grid.dart';
import 'sand_simulator.dart';
import 'bridge_detector.dart';

class ClearedBridgeAnimation {
  ClearedBridgeAnimation(this.indices, this.colorIndex, this.timer);
  final List<int> indices;
  final int colorIndex;
  double timer;
}

class ArenaEngine implements GameEngine {
  ArenaEngine({int? seed})
    : _factory = PieceFactory(
        seed: seed,
        maxColors: 5,
      ), // Aumentamos a 5 colores para mayor dificultad en arena
      _sandSim = SandSimulator(seed: seed, diagonalSlideProbability: 0.05), // 5% de probabilidad (ligeramente menos esparcimiento)
      _pieceGrid = Grid(gridRows, gridColumns),
      sandGrid = SandGrid();

  final PieceFactory _factory;
  final SandSimulator _sandSim;
  final BridgeDetector _bridgeDetector = const BridgeDetector();

  /// Coarse grid used during piece-falling phase (10×20).
  final Grid _pieceGrid;

  /// Fine-grained sand particle grid (40×80). Exposed for rendering.
  final SandGrid sandGrid;

  @override
  void Function(int damage)? onGarbageSent;

  @override
  int pendingGarbage = 0;

  @override
  void receiveGarbage(int lines) {
    pendingGarbage += lines;
  }

  DateTime? _reviveStartTime;
  double? _customReviveCountdown;

  @override
  double get reviveCountdown {
    if (_customReviveCountdown != null) return _customReviveCountdown!;
    if (_reviveStartTime == null) return 0.0;
    final elapsed = DateTime.now().difference(_reviveStartTime!).inMilliseconds / 1000.0;
    final remaining = 4.0 - elapsed;
    if (remaining <= 0) {
      _reviveStartTime = null;
      return 0.0;
    }
    return remaining;
  }

  set reviveCountdown(double value) {
    if (value <= 0) {
      _customReviveCountdown = null;
      _reviveStartTime = null;
    } else {
      _customReviveCountdown = value;
    }
  }

  // ─── State ──────────────────────────────────────────────────

  @override
  GameState state = const GameState();

  @override
  CubixPiece? activePiece;

  @override
  CubixPiece? nextPiece;

  @override
  CubixPiece? heldPiece;

  @override
  bool canHold = true;

  @override
  double shakeTimer = 0.0;

  @override
  List<FloatingText> floatingTexts = [];

  @override
  List<HardDropTrail> hardDropTrails = [];

  @override
  int get highScore => ScoreManager.arenaHighScore;

  int currentCombo = 0;

  /// Active bridge animations.
  List<ClearedBridgeAnimation> bridgeAnimations = [];

  int _initialLevel = 1;

  // ─── Internals ──────────────────────────────────────────────

  double _dropTimer = 0;
  bool _hasTouchedGround = false;
  double _timeSinceFirstTouch = 0;
  bool _isLocked = false;
  bool _isFastDropping = false;
  double _sandTimer = 0;
  double _bridgeCheckTimer = 0;

  /// Sand simulation runs at a higher rate than piece drops.
  static const double _sandStepInterval = 1.0 / 120.0; // 120 Hz

  double get _dropInterval =>
      max(0.02, baseDropInterval - (state.level - 1) * 0.15); // Aumentamos la velocidad de caída drásticamente por nivel

  // ─── Lifecycle ──────────────────────────────────────────────

  @override
  void reset({int initialLevel = 1}) {
    _initialLevel = initialLevel;
    _pieceGrid.clear();
    sandGrid.clear();
    _factory.reset();
    _reviveStartTime = null;
    _customReviveCountdown = null;
    state = GameState(status: GameStatus.playing, level: initialLevel);
    _dropTimer = 0;
    _hasTouchedGround = false;
    _timeSinceFirstTouch = 0;
    _isLocked = false;
    _sandTimer = 0;
    _bridgeCheckTimer = 0;
    bridgeAnimations.clear();
    heldPiece = null;
    canHold = true;
    shakeTimer = 0.0;
    floatingTexts.clear();
    hardDropTrails.clear();
    currentCombo = 0;
    pendingGarbage = 0;
    _spawnPiece();
  }

  @override
  void forceGameOver() {
    state = state.copyWith(status: GameStatus.gameOver);
  }

  @override
  void togglePause() {
    if (state.status == GameStatus.playing) {
      AudioService.instance.playPausa();
      state = state.copyWith(status: GameStatus.paused);
    } else if (state.status == GameStatus.paused) {
      AudioService.instance.playPausa();
      state = state.copyWith(status: GameStatus.playing);
    }
  }

  @override
  void revive() {
    if (state.status != GameStatus.gameOver) return;
    
    // Find topmost occupied row of sand
    int topSandRow = -1;
    for (int r = 0; r < sandGrid.rows; r++) {
      for (int c = 0; c < sandGrid.cols; c++) {
        if (sandGrid.getCell(r, c) != null) {
          topSandRow = r;
          break;
        }
      }
      if (topSandRow != -1) break;
    }

    // Eliminate top sand that reached the danger ceiling (approx. 40 rows)
    // and ensure spawn area (top 32 rows / 4 block rows) is completely clear.
    // The bottom sand foundation remains intact!
    if (topSandRow != -1) {
      final clearToRow = min(sandGrid.rows - 1, max(32, topSandRow + 40));
      for (int r = 0; r <= clearToRow; r++) {
        for (int c = 0; c < sandGrid.cols; c++) {
          sandGrid.setCell(r, c, null);
        }
      }
    } else {
      for (int r = 0; r < 32; r++) {
        for (int c = 0; c < sandGrid.cols; c++) {
          sandGrid.setCell(r, c, null);
        }
      }
    }

    _customReviveCountdown = null;
    _reviveStartTime = DateTime.now();
    state = state.copyWith(status: GameStatus.playing);
    _spawnPiece();
  }

  @override
  void update(double dt) {
    if (state.status != GameStatus.playing) return;

    if (reviveCountdown > 0) {
      if (_customReviveCountdown != null) {
        _customReviveCountdown = _customReviveCountdown! - dt;
        if (_customReviveCountdown! <= 0) {
          _customReviveCountdown = null;
        }
      }
      return; // Pause the game loop while counting down
    }

    state = state.copyWith(elapsedSeconds: state.elapsedSeconds + dt);

    final toRemove = <ClearedBridgeAnimation>[];
    for (final anim in bridgeAnimations) {
      anim.timer -= dt;
      if (anim.timer <= 0) toRemove.add(anim);
    }
    for (final anim in toRemove) {
      bridgeAnimations.remove(anim);
    }

    if (shakeTimer > 0) {
      shakeTimer -= dt;
      if (shakeTimer < 0) shakeTimer = 0;
    }

    final textsToRemove = <FloatingText>[];
    for (final t in floatingTexts) {
      t.timer -= dt;
      if (t.timer <= 0) textsToRemove.add(t);
    }
    for (final t in textsToRemove) {
      floatingTexts.remove(t);
    }

    final trailsToRemove = <HardDropTrail>[];
    for (final t in hardDropTrails) {
      t.timer -= dt;
      if (t.timer <= 0) trailsToRemove.add(t);
    }
    for (final t in trailsToRemove) {
      hardDropTrails.remove(t);
    }

    // Ejecuta SIEMPRE la fase de arena (físicas continuas)
    _updateSandPhase(dt);

    if (activePiece != null) {
      _updatePiecePhase(dt);
    }
  }

  // ─── Piece Phase ────────────────────────────────────────────

  void _updatePiecePhase(double dt) {
    if (_hasTouchedGround) {
      _timeSinceFirstTouch += dt;
    }

    final isGrounded = _collidesWithAll(activePiece!.moved(1, 0));
    if (isGrounded) {
      if (!_hasTouchedGround) {
        _hasTouchedGround = true;
        _timeSinceFirstTouch = 0;
      }
      if (_timeSinceFirstTouch >= lockDelay) {
        _lockAndDisintegrate();
        return;
      }
    }

    _dropTimer += dt * (_isFastDropping ? 10.0 : 1.0);
    if (_dropTimer >= _dropInterval) {
      _dropTimer = 0;
      _tryMoveDown();
    }
  }

  @override
  void setFastDrop(bool enabled) {
    _isFastDropping = enabled;
  }

  void _tryMoveDown() {
    if (activePiece == null) return;
    final below = activePiece!.moved(1, 0);
    if (!_collidesWithAll(below)) {
      activePiece = below;
    }
  }

  /// Check collision against both the piece grid boundaries AND existing sand.
  bool _collidesWithAll(CubixPiece piece) {
    for (final cell in piece.absoluteCells) {
      // Out of bounds
      if (cell.row < 0 ||
          cell.row >= gridRows ||
          cell.col < 0 ||
          cell.col >= gridColumns) {
        return true;
      }
      // Check sand grid for collisions (any grain in the block area)
      final sandTopRow = cell.row * sandScale;
      final sandLeftCol = cell.col * sandScale;
      for (int sr = 0; sr < sandScale; sr++) {
        for (int sc = 0; sc < sandScale; sc++) {
          if (sandGrid.getCell(sandTopRow + sr, sandLeftCol + sc) != null) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Lock the piece and convert blocks into sand particles.
  void _lockAndDisintegrate() {
    if (activePiece == null || _isLocked) return;
    _isLocked = true;

    for (final cell in activePiece!.absoluteCells) {
      final sandTopRow = cell.row * sandScale;
      final sandLeftCol = cell.col * sandScale;
      sandGrid.placeBlock(sandTopRow, sandLeftCol, activePiece!.colorIndex);
    }

    if (sandGrid.checkTopOut()) {
      AudioService.instance.playPerderGanar();
      state = state.copyWith(status: GameStatus.gameOver);
      return;
    }

    activePiece = null;
    _hasTouchedGround = false;
    _timeSinceFirstTouch = 0;
    _isLocked = false;
    _sandTimer = 0;

    // Spawn de la siguiente pieza inmediatamente (no esperamos a que la arena caiga)
    _spawnPiece();
    
    // Si no hubo arena activa ni piezas y hay garbage, lo aplicamos (Arena es más laxo con esto, aplicamos al soltar)
    if (pendingGarbage > 0) {
      int holeCol = Random().nextInt(gridColumns);

      if (sandGrid.checkGarbageGameOver(pendingGarbage)) {
        AudioService.instance.playPerderGanar();
        state = state.copyWith(status: GameStatus.gameOver);
        return;
      }

      sandGrid.insertGarbageLines(pendingGarbage, holeCol);
      
      if (activePiece != null) {
        activePiece = activePiece!.moved(-pendingGarbage, 0);
      }
      
      pendingGarbage = 0;
    }
  }

  // ─── Sand Phase ─────────────────────────────────────────────

  void _updateSandPhase(double dt) {
    _sandTimer += dt;
    _bridgeCheckTimer += dt;

    // Run multiple sand steps per frame for faster settling
    int steps = 0;
    while (_sandTimer >= _sandStepInterval && steps < 4) {
      _sandTimer -= _sandStepInterval;
      steps++;
      _sandSim.step(sandGrid);
    }

    // Check for bridges periodically or after sand settles
    if (!sandGrid.hasActivity || _bridgeCheckTimer >= 0.25) {
      final bridge = _bridgeDetector.detect(sandGrid);
      if (bridge.found) {
        AudioService.instance.playRomperFila();
        _bridgeCheckTimer = 0;
        bridgeAnimations.add(
          ClearedBridgeAnimation(
            List.from(bridge.connectedIndices),
            bridge.colorIndex,
            0.5,
          ),
        );
        sandGrid.removeGrains(bridge.connectedIndices);

        currentCombo++;
        if (currentCombo > 1) {
          floatingTexts.add(
            FloatingText('COMBO x$currentCombo', 1.5, 0xFFFFD600),
          );
        }

        // Count size of bridge to determine popup
        int count = bridge.connectedIndices.length;
        if (count > 20) {
          shakeTimer = 0.3;
          floatingTexts.add(FloatingText('SAND BLAST!', 2.0, 0xFF00E5FF));
          HapticFeedback.heavyImpact();
        } else if (count > 10) {
          floatingTexts.add(FloatingText('GREAT!', 1.0, 0xFF00E676));
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.lightImpact();
        }

        final newLines = state.linesCleared + 1;
        final newLevel = _initialLevel + (newLines ~/ linesPerLevel);

        final newScore = state.score + 100 * state.level;
        if (newScore > ScoreManager.arenaHighScore) {
          ScoreManager.saveArenaScore(newScore);
        }

        ScoreManager.addCoins(10);

        if (newLevel > state.level) {
          floatingTexts.add(FloatingText('LEVEL UP!', 3.0, 0xFFFF1744));
        }
        
        // Simple damage for Arena (no T-spins, just based on size)
        int damage = count > 20 ? 4 : (count > 10 ? 2 : 1);
        
        // Combo damage
        if (currentCombo > 0) {
          if (currentCombo >= 1 && currentCombo <= 3) {
            damage += 1;
          } else if (currentCombo >= 4) damage += 2;
        }
        
        if (damage > 0) {
          if (pendingGarbage > 0) {
            int offset = min(pendingGarbage, damage);
            pendingGarbage -= offset;
            damage -= offset;
          }
          if (damage > 0 && onGarbageSent != null) {
            onGarbageSent!(damage);
          }
        }

        state = state.copyWith(
          score: newScore,
          linesCleared: newLines,
          level: newLevel,
        );
        // Stay in sand phase — more sand might need to settle
        return;
      }

      if (!sandGrid.hasActivity) {
        // Sand settled, reset variables but DO NOT spawn piece (already spawned)
        _bridgeCheckTimer = 0;
        currentCombo = 0;
      }
    }
  }

  // ─── Player Input ───────────────────────────────────────────

  @override
  void moveLeft() {
    if (state.status != GameStatus.playing || activePiece == null) return;
    final moved = activePiece!.moved(0, -1);
    if (!_collidesWithAll(moved)) {
      activePiece = moved;
      HapticFeedback.lightImpact();
    }
  }

  @override
  void moveRight() {
    if (state.status != GameStatus.playing || activePiece == null) return;
    final moved = activePiece!.moved(0, 1);
    if (!_collidesWithAll(moved)) {
      activePiece = moved;
      HapticFeedback.lightImpact();
    }
  }

  @override
  void rotateClockwise() {
    if (state.status != GameStatus.playing || activePiece == null) return;
    final piece = activePiece!;
    final newRotation = piece.nextRotation;
    final rotated = piece.rotated(newRotation);

    if (!_collidesWithAll(rotated)) {
      activePiece = rotated;
      HapticFeedback.lightImpact();
      return;
    }

    final kickKey = '${piece.rotation.index}>${newRotation.index}';
    final kicks = wallKickData[piece.shape]?[kickKey];
    if (kicks != null) {
      for (final kick in kicks) {
        final kicked = rotated.moved(kick.row, kick.col);
        if (!_collidesWithAll(kicked)) {
          activePiece = kicked;
          HapticFeedback.lightImpact();
          return;
        }
      }
    }
  }

  @override
  void softDrop() {
    if (state.status != GameStatus.playing || activePiece == null) return;
    final moved = activePiece!.moved(1, 0);
    if (!_collidesWithAll(moved)) {
      activePiece = moved;
      state = state.copyWith(score: state.score + softDropScore);
      _dropTimer = 0;
    }
  }

  @override
  void hardDrop() {
    if (state.status != GameStatus.playing || activePiece == null) return;
    var piece = activePiece!;
    final startRow = piece.row;
    while (!_collidesWithAll(piece.moved(1, 0))) {
      piece = piece.moved(1, 0);
    }
    activePiece = piece;

    // Add trail
    for (final cell in piece.absoluteCells) {
      hardDropTrails.add(
        HardDropTrail(
          cell.col,
          startRow + (cell.row - piece.row),
          cell.row,
          piece.colorIndex,
          0.3,
        ),
      );
    }

    final newScore = state.score + 2;
    if (newScore > ScoreManager.arenaHighScore) {
      ScoreManager.saveArenaScore(newScore);
    }

    state = state.copyWith(score: newScore);
    shakeTimer = 0.2;
    HapticFeedback.heavyImpact();
    _lockAndDisintegrate();
  }

  @override
  void holdPiece() {
    if (state.status != GameStatus.playing || activePiece == null || !canHold) {
      return;
    }

    final currentShape = activePiece!.shape;
    final currentColor = activePiece!.colorIndex;

    // Resetear el estado de bloqueo para que la nueva pieza no se bloquee inmediatamente
    _hasTouchedGround = false;
    _timeSinceFirstTouch = 0;

    if (heldPiece == null) {
      heldPiece = CubixPiece(
        shape: currentShape,
        colorIndex: currentColor,
        row: 0,
        col: 3,
      );
      _spawnPiece();
    } else {
      final tempShape = heldPiece!.shape;
      final tempColor = heldPiece!.colorIndex;
      heldPiece = CubixPiece(
        shape: currentShape,
        colorIndex: currentColor,
        row: 0,
        col: 3,
      );
      activePiece = CubixPiece(
        shape: tempShape,
        colorIndex: tempColor,
        row: 0,
        col: 3,
      );
      _dropTimer = 0;
    }

    canHold = false;
  }

  // ─── Helpers ────────────────────────────────────────────────

  void _spawnPiece() {
    if (nextPiece != null) {
      activePiece = nextPiece!.withPosition(0, 3);
    } else {
      activePiece = _factory.next();
    }
    nextPiece = _factory.next(spawnRow: 0, spawnCol: 3);
    canHold = true;

    if (_collidesWithAll(activePiece!)) {
      activePiece = null;
      AudioService.instance.playPerderGanar();
      state = state.copyWith(status: GameStatus.gameOver);
    }

    _dropTimer = 0;
  }


}
