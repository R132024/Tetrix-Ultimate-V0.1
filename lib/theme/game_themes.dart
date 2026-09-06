import 'package:flutter/material.dart';

enum PieceStyle {
  classic,
  neon,
  metallic,
  matrix,
}

class ThemePalette {
  const ThemePalette({
    required this.id,
    required this.name,
    required this.price,
    required this.backgroundColors,
    required this.pieceColors,
    required this.pieceStyle,
  });

  final String id;
  final String name;
  final int price;
  final List<Color> backgroundColors;
  final List<Color> pieceColors;
  final PieceStyle pieceStyle;
}

class GameThemes {
  static const classicId = 'classic';
  static const neonId = 'neon';
  static const metallicId = 'metallic';
  static const matrixId = 'matrix';

  static final Map<String, ThemePalette> themes = {
    classicId: const ThemePalette(
      id: classicId,
      name: 'Dibujado',
      price: 0,
      pieceStyle: PieceStyle.classic,
      backgroundColors: [
        Color(0xFFEEDDBC),
        Color(0xFFFFD600),
        Color(0xFFAA00FF),
        Color(0xFF00E676),
        Color(0xFFFF1744),
      ],
      pieceColors: [
        Color(0xFFCC3333), // I - Rojo apagado
        Color(0xFF339933), // O - Verde hoja
        Color(0xFF3366CC), // T - Azul marino
        Color(0xFFDDAA33), // S - Amarillo mostaza
        Color(0xFF993399), // Z - Morado
        Color(0xFFCC6633), // J - Naranja ladrillo
        Color(0xFF33AAAA), // L - Cerceta
      ],
    ),
    neonId: const ThemePalette(
      id: neonId,
      name: 'Neon Style',
      price: 500,
      pieceStyle: PieceStyle.neon,
      backgroundColors: [
        Color(0xFFFF00FF),
        Color(0xFF00FFFF),
        Color(0xFF8A2BE2),
        Color(0xFFFF1493),
        Color(0xFF00CED1),
      ],
      pieceColors: [
        Color(0xFFFF0000), // Rojo neon
        Color(0xFF00FF00), // Verde neon
        Color(0xFF0088FF), // Azul neon
        Color(0xFFFFCC00), // Amarillo neon
        Color(0xFFFF00FF), // Magenta neon
        Color(0xFF00FFFF), // Cyan neon
        Color(0xFFFF8800), // Naranja neon
      ],
    ),
    metallicId: const ThemePalette(
      id: metallicId,
      name: 'Metálico',
      price: 1500,
      pieceStyle: PieceStyle.metallic,
      backgroundColors: [
        Color(0xFF444444),
        Color(0xFF666666),
        Color(0xFF888888),
        Color(0xFFAAAAAA),
        Color(0xFFCCCCCC),
      ],
      pieceColors: [
        Color(0xFF9E0000), // Dark Red
        Color(0xFF006400), // Dark Green
        Color(0xFF00008B), // Dark Blue
        Color(0xFFB8860B), // Dark Goldenrod
        Color(0xFF4B0082), // Indigo
        Color(0xFF2F4F4F), // Dark Slate Gray
        Color(0xFF8B4500), // Dark Orange
      ],
    ),
    matrixId: const ThemePalette(
      id: matrixId,
      name: 'Matrix Hacker',
      price: 1000,
      pieceStyle: PieceStyle.matrix,
      backgroundColors: [
        Color(0xFF00FF00),
        Color(0xFF32CD32),
        Color(0xFF00FA9A),
        Color(0xFF00FF7F),
        Color(0xFF228B22),
      ],
      pieceColors: [
        Color(0xFFFF0000), // Red
        Color(0xFF00FF00), // Green
        Color(0xFF0088FF), // Blue
        Color(0xFFFFCC00), // Yellow
        Color(0xFFFF00FF), // Purple
        Color(0xFF00FFFF), // Cyan
        Color(0xFFFFFFFF), // White
      ],
    ),
  };

  static ThemePalette getTheme(String id) {
    return themes[id] ?? themes[classicId]!;
  }
}

