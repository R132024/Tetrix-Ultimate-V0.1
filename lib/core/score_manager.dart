import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ScoreManager {
  static late SharedPreferences _prefs;

  static const String _classicKey = 'classicHighScore';
  static const String _arenaKey = 'arenaHighScore';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    coinsNotifier.value = coins;
    premiumNotifier.value = isPremium;
  }

  static int get classicHighScore => _prefs.getInt(_classicKey) ?? 0;
  static Future<void> saveClassicScore(int score) async {
    if (score > classicHighScore) {
      await _prefs.setInt(_classicKey, score);
    }
  }

  static int get arenaHighScore => _prefs.getInt(_arenaKey) ?? 0;
  static Future<void> saveArenaScore(int score) async {
    if (score > arenaHighScore) {
      await _prefs.setInt(_arenaKey, score);
    }
  }

  // --- Economy & Themes ---
  static const String _coinsKey = 'cubix_coins';
  static const String _currentThemeKey = 'cubix_current_theme';
  static const String _unlockedThemesKey = 'cubix_unlocked_themes';

  static const String _isPremiumKey = 'cubix_is_premium';

  static final ValueNotifier<int> coinsNotifier = ValueNotifier(0);
  static final ValueNotifier<bool> premiumNotifier = ValueNotifier(false);

  static bool get isPremium => _prefs.getBool(_isPremiumKey) ?? false;
  static Future<void> setPremium(bool val) async {
    await _prefs.setBool(_isPremiumKey, val);
    premiumNotifier.value = val;
    if (val) {
      // Si se vuelve Premium, regalar todos los temas
      await unlockTheme('neon');
      await unlockTheme('matrix');
      await unlockTheme('metallic');
    }
  }

  static int get coins => _prefs.getInt(_coinsKey) ?? 0;
  static Future<void> addCoins(int amount) async {
    final newVal = coins + amount;
    await _prefs.setInt(_coinsKey, newVal);
    coinsNotifier.value = newVal;
  }

  static Future<bool> spendCoins(int amount) async {
    final current = coins;
    if (current >= amount) {
      final newVal = current - amount;
      await _prefs.setInt(_coinsKey, newVal);
      coinsNotifier.value = newVal;
      return true;
    }
    return false;
  }

  static String get currentTheme =>
      _prefs.getString(_currentThemeKey) ?? 'classic';
  static Future<void> setCurrentTheme(String themeId) async {
    await _prefs.setString(_currentThemeKey, themeId);
  }

  static List<String> get unlockedThemes =>
      _prefs.getStringList(_unlockedThemesKey) ?? ['classic'];
  static Future<void> unlockTheme(String themeId) async {
    final list = unlockedThemes;
    if (!list.contains(themeId)) {
      list.add(themeId);
      await _prefs.setStringList(_unlockedThemesKey, list);
    }
  }
}
