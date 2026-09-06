import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cubix_blast/core/score_manager.dart';

class DailyReward {
  final int day;
  final int coins;
  final bool isPremium;

  const DailyReward({
    required this.day,
    required this.coins,
    this.isPremium = false,
  });
}

class DailyRewardsManager {
  static late SharedPreferences _prefs;
  static const String _streakKey = 'cubix_daily_streak';
  static const String _lastClaimDateKey = 'cubix_last_claim_date';

  // 7 Days of rewards
  static const List<DailyReward> rewards = [
    DailyReward(day: 1, coins: 50),
    DailyReward(day: 2, coins: 100),
    DailyReward(day: 3, coins: 150),
    DailyReward(day: 4, coins: 200),
    DailyReward(day: 5, coins: 300),
    DailyReward(day: 6, coins: 500),
    DailyReward(day: 7, coins: 1000, isPremium: true), // Mega reward
  ];

  static final ValueNotifier<int> currentStreakNotifier = ValueNotifier(0);
  static final ValueNotifier<bool> canClaimTodayNotifier = ValueNotifier(false);

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _checkDailyStatus();
  }

  static void _checkDailyStatus() {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    
    final lastClaimStr = _prefs.getString(_lastClaimDateKey);
    int streak = _prefs.getInt(_streakKey) ?? 0;

    if (lastClaimStr == null) {
      // First time playing
      streak = 0;
      canClaimTodayNotifier.value = true;
    } else {
      final lastClaimDate = DateTime.parse(lastClaimStr);
      final difference = DateTime(now.year, now.month, now.day)
          .difference(DateTime(lastClaimDate.year, lastClaimDate.month, lastClaimDate.day))
          .inDays;

      if (difference == 0) {
        // Already claimed today
        canClaimTodayNotifier.value = false;
      } else if (difference == 1) {
        // Continuous streak
        if (streak >= 7) {
          streak = 0; // Reset after day 7
        }
        canClaimTodayNotifier.value = true;
      } else {
        // Streak broken (missed a day)
        streak = 0;
        canClaimTodayNotifier.value = true;
      }
    }

    currentStreakNotifier.value = streak;
    _prefs.setInt(_streakKey, streak);
  }

  static Future<DailyReward?> claimReward() async {
    if (!canClaimTodayNotifier.value) return null;

    final streak = currentStreakNotifier.value;
    final reward = rewards[streak];

    // Grant reward
    ScoreManager.addCoins(reward.coins);

    // Update streak and date
    final newStreak = streak + 1;
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await _prefs.setInt(_streakKey, newStreak);
    await _prefs.setString(_lastClaimDateKey, todayStr);

    currentStreakNotifier.value = newStreak;
    canClaimTodayNotifier.value = false;

    return reward;
  }
}
