import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerProfile {
  final int level;
  final int xp;
  final int xpRequired;

  const PlayerProfile({
    required this.level,
    required this.xp,
    required this.xpRequired,
  });

  double get progress => xp / xpRequired;

  PlayerProfile copyWith({int? level, int? xp, int? xpRequired}) {
    return PlayerProfile(
      level: level ?? this.level,
      xp: xp ?? this.xp,
      xpRequired: xpRequired ?? this.xpRequired,
    );
  }
}

class PlayerManager {
  static late SharedPreferences _prefs;
  static const String _xpKey = 'cubix_player_xp';
  static const String _levelKey = 'cubix_player_level';

  static final ValueNotifier<PlayerProfile> profileNotifier = 
      ValueNotifier(const PlayerProfile(level: 1, xp: 0, xpRequired: 100));

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final xp = _prefs.getInt(_xpKey) ?? 0;
    final level = _prefs.getInt(_levelKey) ?? 1;
    profileNotifier.value = PlayerProfile(
      level: level,
      xp: xp,
      xpRequired: _calculateXpRequired(level),
    );
  }

  static int _calculateXpRequired(int level) {
    return 100 * level; // Progresión lineal simple
  }

  // Retorna true si el jugador subió de nivel
  static Future<bool> addXp(int amount) async {
    int currentXp = profileNotifier.value.xp + amount;
    int currentLevel = profileNotifier.value.level;
    int requiredXp = _calculateXpRequired(currentLevel);
    bool leveledUp = false;

    while (currentXp >= requiredXp) {
      currentXp -= requiredXp;
      currentLevel++;
      requiredXp = _calculateXpRequired(currentLevel);
      leveledUp = true;
    }

    await _prefs.setInt(_xpKey, currentXp);
    await _prefs.setInt(_levelKey, currentLevel);

    profileNotifier.value = PlayerProfile(
      level: currentLevel,
      xp: currentXp,
      xpRequired: requiredXp,
    );

    return leveledUp;
  }
}
