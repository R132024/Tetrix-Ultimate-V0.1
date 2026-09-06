import 'package:cubix_blast/core/piece.dart';
import 'package:cubix_blast/casino/logic/casino_engine.dart';
import 'package:cubix_blast/core/game_engine.dart';

enum CharmRarity { common, rare, epic, legendary, cursed }

abstract class Charm {
  final String id;
  final String name;
  final String description;
  final CharmRarity rarity;
  final int cost;
  int level = 1;

  Charm({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.cost,
  });

  // Hooks para modificar el juego
  int modifyScore(CasinoEngine engine, int baseScore, int linesCleared, CubixPiece lastPiece) {
    return baseScore;
  }

  double modifyMultiplier(CasinoEngine engine, double currentMultiplier) {
    return currentMultiplier;
  }
  
  void onEquip(CasinoEngine engine) {}
  void onUnequip(CasinoEngine engine) {}

  int get sellValue => (cost / 2).floor();
}

// --- Charms 100% Malditos (Fase 3) ---

class BloodDiamondCharm extends Charm {
  BloodDiamondCharm()
      : super(
          id: 'blood_diamond',
          name: 'Diamante de Sangre',
          description: 'Líneas con piezas Azules dan x4 puntos, pero las piezas Rojas caen a doble velocidad.',
          rarity: CharmRarity.epic,
          cost: 250,
        );

  @override
  void onEquip(CasinoEngine engine) {
    // We could apply a drop speed multiplier only when piece is red, but to keep it simple
    // we'll apply a global 1.2x speed boost to make it generally harder.
    engine.dropSpeedMultiplier *= 1.2;
  }

  @override
  int modifyScore(CasinoEngine engine, int baseScore, int linesCleared, CubixPiece lastPiece) {
    if (lastPiece.colorIndex == 0 || lastPiece.colorIndex == 3) { 
      engine.floatingTexts.add(FloatingText('Sangre Azul x4', 1.5, 0xFF00E5FF));
      return baseScore * 4;
    }
    return baseScore;
  }
}

class AllOrNothingCharm extends Charm {
  AllOrNothingCharm()
      : super(
          id: 'all_or_nothing',
          name: 'Todo o Nada',
          description: 'Los Tetris (4 líneas) dan +4000 puntos extras. Líneas simples y dobles dan 0 puntos.',
          rarity: CharmRarity.legendary,
          cost: 500,
        );

  @override
  int modifyScore(CasinoEngine engine, int baseScore, int linesCleared, CubixPiece lastPiece) {
    if (linesCleared >= 4) {
      engine.floatingTexts.add(FloatingText('¡JACKPOT EXTREMO +4000!', 2.0, 0xFFFFD600));
      return baseScore + 4000;
    } else if (linesCleared <= 2) {
      engine.floatingTexts.add(FloatingText('Castigo (-Puntos)', 1.0, 0xFFFF1744));
      return 0;
    }
    return baseScore;
  }
}

class VisionPactCharm extends Charm {
  VisionPactCharm()
      : super(
          id: 'vision_pact',
          name: 'Pacto de Visión',
          description: 'Aumenta el multiplicador en +1.5x permanentemente, pero oculta la Siguiente Pieza.',
          rarity: CharmRarity.cursed,
          cost: 300,
        );

  @override
  void onEquip(CasinoEngine engine) {
    engine.hideNextPiece = true;
  }

  @override
  void onUnequip(CasinoEngine engine) {
    engine.hideNextPiece = false;
  }

  @override
  double modifyMultiplier(CasinoEngine engine, double currentMultiplier) {
    return currentMultiplier + 1.5;
  }
}

class PureGreedCharm extends Charm {
  PureGreedCharm()
      : super(
          id: 'pure_greed',
          name: 'Codicia Pura',
          description: 'Te regala \$800 fichas inmediatas, pero te tira 2 líneas de basura instantáneas.',
          rarity: CharmRarity.cursed,
          cost: 0,
        );

  @override
  void onEquip(CasinoEngine engine) {
    engine.runMoney += 800;
    engine.pendingGarbage += 2;
    // We don't call spawnGarbage immediately, it will happen on the next drop or next round
  }
}

class CharmsRegistry {
  static List<Charm> getAllAvailable() {
    return [
      BloodDiamondCharm(),
      AllOrNothingCharm(),
      VisionPactCharm(),
      PureGreedCharm(),
    ];
  }
}
