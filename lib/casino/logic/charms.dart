import 'package:cubix_blast/core/piece.dart';
import 'package:cubix_blast/casino/logic/casino_engine.dart';
import 'package:cubix_blast/core/game_engine.dart';

enum CharmRarity { common, rare, epic, legendary, cursed, punishment }

abstract class Charm {
  final String id;
  final String icon; // 8-bit aesthetic Emoji
  final String name;
  final String description;
  final CharmRarity rarity;
  final int cost;
  int level = 1;

  Charm({
    required this.id,
    required this.icon,
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

// ==========================================
// ========== EXISTENTES MEJORADOS ==========
// ==========================================

class BloodDiamondCharm extends Charm {
  BloodDiamondCharm()
      : super(
          id: 'blood_diamond',
          icon: '💎',
          name: 'Diamante de Sangre',
          description: 'Líneas con piezas Azules dan x4 puntos, pero el juego es un 20% más rápido.',
          rarity: CharmRarity.epic,
          cost: 250,
        );

  @override
  void onEquip(CasinoEngine engine) {
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
          icon: '🎰',
          name: 'Todo o Nada',
          description: 'Los Tetris (4 líneas) dan +4000 puntos extras. Líneas simples y dobles dan 0 puntos.',
          rarity: CharmRarity.legendary,
          cost: 500,
        );

  @override
  int modifyScore(CasinoEngine engine, int baseScore, int linesCleared, CubixPiece lastPiece) {
    if (linesCleared >= 4) {
      engine.floatingTexts.add(FloatingText('¡JACKPOT +4000!', 2.0, 0xFFFFD600));
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
          icon: '👁️',
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
          icon: '💰',
          name: 'Codicia Pura',
          description: 'Te regala \$800 fichas inmediatas, pero te tira 2 líneas de basura instantáneas.',
          rarity: CharmRarity.cursed,
          cost: 0,
        );

  @override
  void onEquip(CasinoEngine engine) {
    engine.runMoney += 800;
    engine.pendingGarbage += 2;
  }
}

// ==========================================
// ============= NUEVOS AMULETOS ============
// ==========================================

class SlotMachineCharm extends Charm {
  SlotMachineCharm()
      : super(
          id: 'slot_machine',
          icon: '🍒',
          name: 'Tragamonedas',
          description: '+15 Fichas extra por cada línea limpiada.',
          rarity: CharmRarity.common,
          cost: 100,
        );

  @override
  void onEquip(CasinoEngine engine) {
    engine.bonusCoinsPerLine += 15;
  }
}

class CopperShieldCharm extends Charm {
  CopperShieldCharm()
      : super(
          id: 'copper_shield',
          icon: '🛡️',
          name: 'Escudo de Cobre',
          description: 'Reduce la basura recibida en un 50%.',
          rarity: CharmRarity.rare,
          cost: 200,
        );

  @override
  void onEquip(CasinoEngine engine) {
    engine.garbageMultiplier *= 0.5;
  }
}

class ControlledChaosCharm extends Charm {
  ControlledChaosCharm()
      : super(
          id: 'controlled_chaos',
          icon: '🎲',
          name: 'Caos Controlado',
          description: 'Multiplicador permanente de x2.5, pero tus controles de movimiento se invierten.',
          rarity: CharmRarity.cursed,
          cost: 150,
        );

  @override
  void onEquip(CasinoEngine engine) {
    engine.invertedControls = true;
  }
  
  @override
  double modifyMultiplier(CasinoEngine engine, double currentMultiplier) {
    return currentMultiplier + 1.5; // (base 1.0 + 1.5 = 2.5)
  }
}

class SnailShellCharm extends Charm {
  SnailShellCharm()
      : super(
          id: 'snail_shell',
          icon: '🐌',
          name: 'Caparazón',
          description: 'La velocidad de caída de las piezas se reduce a la mitad.',
          rarity: CharmRarity.epic,
          cost: 300,
        );

  @override
  void onEquip(CasinoEngine engine) {
    engine.dropSpeedMultiplier *= 0.5;
  }
}

class TouchOfDeathCharm extends Charm {
  TouchOfDeathCharm()
      : super(
          id: 'touch_of_death',
          icon: '💀',
          name: 'Toque de Muerte',
          description: 'Limpiar líneas simples te castiga quitándote 100 Fichas.',
          rarity: CharmRarity.punishment,
          cost: 0,
        );

  @override
  int modifyScore(CasinoEngine engine, int baseScore, int linesCleared, CubixPiece lastPiece) {
    if (linesCleared == 1) {
      engine.runMoney -= 100;
      if (engine.runMoney < 0) engine.runMoney = 0;
      engine.floatingTexts.add(FloatingText('-100 Fichas!', 1.0, 0xFFFF1744));
    }
    return baseScore;
  }
}

class MillionaireCharm extends Charm {
  MillionaireCharm()
      : super(
          id: 'millionaire',
          icon: '💸',
          name: 'Millonario',
          description: 'Recibes \$5000 fichas, pero tu puntuación total se reduce a la mitad.',
          rarity: CharmRarity.legendary,
          cost: 999, // Se asume que el jugador no lo compra, lo obtiene por eventos, pero ponemos 999 por si acaso
        );

  @override
  void onEquip(CasinoEngine engine) {
    engine.runMoney += 5000;
  }

  @override
  double modifyMultiplier(CasinoEngine engine, double currentMultiplier) {
    return currentMultiplier * 0.5;
  }
}

class BrokenHandsCharm extends Charm {
  BrokenHandsCharm()
      : super(
          id: 'broken_hands',
          icon: '🚫',
          name: 'Manos Rotas',
          description: 'Ya no puedes usar la función "Hold" (Guardar), pero ganas x2 de puntuación.',
          rarity: CharmRarity.cursed,
          cost: 150,
        );

  @override
  void onEquip(CasinoEngine engine) {
    engine.disableHold = true;
  }

  @override
  double modifyMultiplier(CasinoEngine engine, double currentMultiplier) {
    return currentMultiplier + 1.0;
  }
}

class BeginnersLuckCharm extends Charm {
  BeginnersLuckCharm()
      : super(
          id: 'beginners_luck',
          icon: '🍀',
          name: 'Suerte del Principiante',
          description: 'Tus primeras 10 líneas en esta partida dan x5 puntos.',
          rarity: CharmRarity.common,
          cost: 50,
        );

  @override
  double modifyMultiplier(CasinoEngine engine, double currentMultiplier) {
    if (engine.state.linesCleared <= 10) {
      return currentMultiplier + 4.0;
    }
    return currentMultiplier;
  }
}

class LightningCharm extends Charm {
  LightningCharm()
      : super(
          id: 'lightning',
          icon: '⚡',
          name: 'Rayo',
          description: 'La velocidad de caída se triplica, pero recibes x3 puntos.',
          rarity: CharmRarity.epic,
          cost: 200,
        );

  @override
  void onEquip(CasinoEngine engine) {
    engine.dropSpeedMultiplier *= 3.0;
  }

  @override
  double modifyMultiplier(CasinoEngine engine, double currentMultiplier) {
    return currentMultiplier + 2.0;
  }
}

class CrystalBallCharm extends Charm {
  CrystalBallCharm()
      : super(
          id: 'crystal_ball',
          icon: '🔮',
          name: 'Bola de Cristal',
          description: 'Fuerza a mostrar la Siguiente Pieza (Anula los efectos de Pacto de Visión).',
          rarity: CharmRarity.rare,
          cost: 180,
        );

  @override
  void onEquip(CasinoEngine engine) {
    engine.hideNextPiece = false;
  }
}

class MasochistCharm extends Charm {
  MasochistCharm()
      : super(
          id: 'masochist',
          icon: '🩸',
          name: 'Masoquista',
          description: 'Recibes el DOBLE de basura, pero tienes un multiplicador de x2 en tus puntos.',
          rarity: CharmRarity.rare,
          cost: 120,
        );

  @override
  void onEquip(CasinoEngine engine) {
    engine.garbageMultiplier *= 2.0;
  }

  @override
  double modifyMultiplier(CasinoEngine engine, double currentMultiplier) {
    return currentMultiplier + 1.0;
  }
}

class ZeroGravityCharm extends Charm {
  ZeroGravityCharm()
      : super(
          id: 'zero_gravity',
          icon: '🚀',
          name: 'Gravedad Cero',
          description: 'La caída es levitante (súper lenta), pero no puedes usar Hold y ganas la mitad de Fichas.',
          rarity: CharmRarity.epic,
          cost: 400,
        );

  @override
  void onEquip(CasinoEngine engine) {
    engine.dropSpeedMultiplier *= 0.2;
    engine.disableHold = true;
    engine.bonusCoinsPerLine -= 7; // Mitiga un poco la ganancia base de 15
  }
}

class GarbageMagnetCharm extends Charm {
  GarbageMagnetCharm()
      : super(
          id: 'garbage_magnet',
          icon: '🧲',
          name: 'Imán de Basura',
          description: 'Toda la basura que recibes se triplica. (Puramente un castigo).',
          rarity: CharmRarity.punishment,
          cost: 0,
        );

  @override
  void onEquip(CasinoEngine engine) {
    engine.garbageMultiplier *= 3.0;
  }
}

class CharmsRegistry {
  static List<Charm> getAllAvailable() {
    return [
      BloodDiamondCharm(),
      AllOrNothingCharm(),
      VisionPactCharm(),
      PureGreedCharm(),
      SlotMachineCharm(),
      CopperShieldCharm(),
      ControlledChaosCharm(),
      SnailShellCharm(),
      TouchOfDeathCharm(),
      MillionaireCharm(),
      BrokenHandsCharm(),
      BeginnersLuckCharm(),
      LightningCharm(),
      CrystalBallCharm(),
      MasochistCharm(),
      ZeroGravityCharm(),
      GarbageMagnetCharm(),
    ];
  }
}
