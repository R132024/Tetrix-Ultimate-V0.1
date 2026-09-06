import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MissionType {
  clearLines,
  playArena,
  usePowerBomb,
  scorePoints,
}

class DailyMission {
  final String id;
  final MissionType type;
  final String title;
  final int target;
  final int current;
  final int xpReward;
  final int coinsReward;
  final bool isCompleted;

  DailyMission({
    required this.id,
    required this.type,
    required this.title,
    required this.target,
    required this.current,
    required this.xpReward,
    required this.coinsReward,
    this.isCompleted = false,
  });

  double get progress => (current / target).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'title': title,
        'target': target,
        'current': current,
        'xpReward': xpReward,
        'coinsReward': coinsReward,
        'isCompleted': isCompleted,
      };

  factory DailyMission.fromJson(Map<String, dynamic> json) {
    return DailyMission(
      id: json['id'],
      type: MissionType.values[json['type'] as int],
      title: json['title'],
      target: json['target'],
      current: json['current'],
      xpReward: json['xpReward'],
      coinsReward: json['coinsReward'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  DailyMission copyWith({int? current, bool? isCompleted}) {
    return DailyMission(
      id: id,
      type: type,
      title: title,
      target: target,
      current: current ?? this.current,
      xpReward: xpReward,
      coinsReward: coinsReward,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class MissionManager {
  static late SharedPreferences _prefs;
  static const String _missionsKey = 'cubix_daily_missions';
  static const String _lastDateKey = 'cubix_missions_date';

  static final ValueNotifier<List<DailyMission>> missionsNotifier = 
      ValueNotifier([]);

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _checkAndGenerateMissions();
  }

  static void _checkAndGenerateMissions() {
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    final savedDate = _prefs.getString(_lastDateKey);

    if (savedDate != today) {
      _generateNewMissions();
      _prefs.setString(_lastDateKey, today);
    } else {
      final jsonStr = _prefs.getString(_missionsKey) ?? '[]';
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      if (jsonList.isEmpty) {
        _generateNewMissions();
      } else {
        missionsNotifier.value = jsonList.map((j) => DailyMission.fromJson(j)).toList();
      }
    }
  }

  static void _generateNewMissions() {
    final templates = [
      DailyMission(
        id: '1',
        type: MissionType.clearLines,
        title: 'Limpia 20 Líneas',
        target: 20,
        current: 0,
        xpReward: 150,
        coinsReward: 50,
      ),
      DailyMission(
        id: '2',
        type: MissionType.playArena,
        title: 'Juega 2 partidas en Arena',
        target: 2,
        current: 0,
        xpReward: 100,
        coinsReward: 30,
      ),
      DailyMission(
        id: '3',
        type: MissionType.scorePoints,
        title: 'Consigue 5,000 Puntos',
        target: 5000,
        current: 0,
        xpReward: 200,
        coinsReward: 100,
      ),
    ];
    
    missionsNotifier.value = templates;
    _saveMissions();
  }

  static Future<void> _saveMissions() async {
    final jsonList = missionsNotifier.value.map((m) => m.toJson()).toList();
    await _prefs.setString(_missionsKey, jsonEncode(jsonList));
  }

  // Registra el progreso y retorna las misiones recién completadas
  static Future<List<DailyMission>> reportProgress(MissionType type, int amount) async {
    if (amount <= 0) return [];

    bool updated = false;
    List<DailyMission> newlyCompleted = [];
    final currentMissions = List<DailyMission>.from(missionsNotifier.value);

    for (int i = 0; i < currentMissions.length; i++) {
      final mission = currentMissions[i];
      if (!mission.isCompleted && mission.type == type) {
        final newCurrent = (mission.current + amount).clamp(0, mission.target);
        if (newCurrent != mission.current) {
          final isCompleted = newCurrent >= mission.target;
          currentMissions[i] = mission.copyWith(
            current: newCurrent,
            isCompleted: isCompleted,
          );
          updated = true;
          if (isCompleted) {
            newlyCompleted.add(currentMissions[i]);
          }
        }
      }
    }

    if (updated) {
      missionsNotifier.value = currentMissions;
      await _saveMissions();
    }
    return newlyCompleted;
  }
}
