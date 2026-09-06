/// Core constants shared across all game modes.
library;

// ─── Classic Grid ───────────────────────────────────────────────
const int gridColumns = 10;
const int gridRows = 20;

// ─── Arena Sand Sub-pixel Resolution ────────────────────────────
/// Each tetromino cell explodes into [sandScale]×[sandScale] grains.
const int sandScale = 8;
const int sandColumns = gridColumns * sandScale; // 80
const int sandRows = gridRows * sandScale; // 160

// ─── Timing ─────────────────────────────────────────────────────
/// Fixed physics update interval in seconds (60 UPS).
const double fixedTimestep = 1.0 / 60.0;

/// Base drop interval in seconds (level 1). Piece drops one row each interval.
const double baseDropInterval = 0.8;

/// Minimum drop interval cap (fastest speed).
const double minDropInterval = 0.05;

/// Lock delay: seconds after landing before piece locks.
const double lockDelay = 0.5;

// ─── Scoring ────────────────────────────────────────────────────
/// Points awarded per number of lines cleared simultaneously.
const List<int> lineScoreTable = [0, 100, 300, 500, 800];

/// Points for a soft-drop step.
const int softDropScore = 1;

/// Points per row for a hard-drop.
const int hardDropScore = 2;

/// Lines needed to advance one level.
const int linesPerLevel = 10;

// ─── Colors ─────────────────────────────────────────────────────
/// Number of distinct piece colors.
const int pieceColorCount = 7;

/// Color index → ARGB hex (Material-inspired neon palette).
const List<int> pieceColors = [
  0xFF00E5FF, // Cyan      (I)
  0xFFEEDDBC, // Crema     (O)
  0xFF7700EE, // Morada    (T)
  0xFF00AA77, // Verde     (S)
  0xFF990066, // Fucsia    (Z)
  0xFF0077AA, // Azul      (J)
  0xFFFF5500, // Naranja   (L)
];
