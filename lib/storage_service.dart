import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'habit.dart';
import 'day_log.dart';
import 'fund_type.dart';
import 'storage_keys.dart';

class StorageService {
  Future<List<Habit>> loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final habitsRaw = prefs.getString(kHabits);

    if (habitsRaw == null) return _seedHabits();

    final list = (jsonDecode(habitsRaw) as List).cast<dynamic>();
    return list
        .map((e) => Habit.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kHabits, jsonEncode(habits.map((e) => e.toJson()).toList()));
  }

  Future<Map<String, DayLog>> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logsRaw = prefs.getString(kDayLogs);

    if (logsRaw == null) return {};

    final map = (jsonDecode(logsRaw) as Map).cast<String, dynamic>();
    return map.map((k, v) => MapEntry(
          k,
          DayLog.fromJson((v as Map).cast<String, dynamic>()),
        ));
  }

  Future<void> saveLogs(Map<String, DayLog> logsByDate) async {
    final prefs = await SharedPreferences.getInstance();
    final map = logsByDate.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(kDayLogs, jsonEncode(map));
  }

  Future<double> loadFund(FundType t) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(t.key) ?? 0;
  }

  Future<void> saveFund(FundType t, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(t.key, value);
  }

  List<Habit> _seedHabits() => [
        Habit(id: 'h_water', name: 'drink water', points: 1, reasoning: 'baseline care'),
        Habit(id: 'h_walk', name: 'walk (10+ min)', points: 2, reasoning: 'movement helps my brain'),
        Habit(id: 'h_workout', name: 'exercise / workout', points: 4, reasoning: 'big effort', isExercise: true),
        Habit(id: 'h_read', name: 'read (10+ min)', points: 2),
        Habit(id: 'h_cleanup', name: 'tidy space (5 min)', points: 1),
      ];
}
