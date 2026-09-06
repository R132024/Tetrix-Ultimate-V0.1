import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists high scores and player names.
///
/// Uses shared_preferences.
class HighScoreStore {
  static const String _keyScorePrefix = 'highscore_score_';
  static const String _keyNamePrefix = 'highscore_name_';
  static const String _keyAllScores = 'all_high_scores_v2';

  static Future<HighScore> getHighScore(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    final score = prefs.getInt('$_keyScorePrefix$mode') ?? 0;
    final name = prefs.getString('$_keyNamePrefix$mode') ?? '----';
    return HighScore(score: score, name: name);
  }

  static Future<void> saveHighScore(
    String mode,
    int score,
    int level,
    String name,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // Save legacy values for compatibility
    final oldScore = prefs.getInt('$_keyScorePrefix$mode') ?? 0;
    if (score > oldScore) {
      await prefs.setInt('$_keyScorePrefix$mode', score);
      await prefs.setString('$_keyNamePrefix$mode', name);
    }

    // Save to the general leaderboard list
    final jsonListStr = prefs.getString(_keyAllScores) ?? '[]';
    List<dynamic> list = jsonDecode(jsonListStr);

    list.add({
      'name': name,
      'mode': mode,
      'level': level,
      'score': score,
      'date': DateTime.now().toIso8601String(),
    });

    // Sort descending by score
    list.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    // Keep top 3
    if (list.length > 3) {
      list = list.sublist(0, 3);
    }

    await prefs.setString(_keyAllScores, jsonEncode(list));
  }

  static Future<List<Map<String, dynamic>>> getAllHighScores() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonListStr = prefs.getString(_keyAllScores) ?? '[]';
    List<dynamic> list = jsonDecode(jsonListStr);

    // Inject legacy records if not present in the new list
    for (final mode in ['classic', 'arena']) {
      final legacyScore = prefs.getInt('$_keyScorePrefix$mode');
      if (legacyScore != null && legacyScore > 0) {
        final legacyName = prefs.getString('$_keyNamePrefix$mode') ?? '----';
        bool found = list.any(
          (e) =>
              e['mode'] == mode &&
              e['score'] == legacyScore &&
              e['name'] == legacyName,
        );
        if (!found) {
          list.add({
            'name': legacyName,
            'mode': mode,
            'level': 1, // fallback level
            'score': legacyScore,
            'date': DateTime.now().toIso8601String(),
          });
        }
      }
    }

    list.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    if (list.length > 3) {
      list = list.sublist(0, 3);
    }
    return list.cast<Map<String, dynamic>>();
  }
}

class HighScore {
  const HighScore({required this.score, required this.name});
  final int score;
  final String name;

  bool get hasRecord => score > 0;
}
