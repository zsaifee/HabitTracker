import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'habit.dart';
import 'day_log.dart';
import 'fund_type.dart';
import 'storage_keys.dart';
import 'profile.dart';

class StorageService {
  String _pkey(String profileId, String base) => 'p_${profileId}__$base';

  // -------------------------
  // Profiles
  // -------------------------
  Future<List<Profile>> loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kProfiles);

    if (raw == null) {
      // seed a default profile on first run
      final p = Profile(id: 'p_default', name: 'me');
      await saveProfiles([p]);
      await setActiveProfileId(p.id);
      return [p];
    }

    final list = (jsonDecode(raw) as List).cast<dynamic>();
    return list.map((e) => Profile.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  Future<void> saveProfiles(List<Profile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kProfiles, jsonEncode(profiles.map((p) => p.toJson()).toList()));
  }

  Future<String> loadActiveProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kActiveProfileId) ?? 'p_default';
  }

  Future<void> setActiveProfileId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kActiveProfileId, id);
  }

  // -------------------------
  // Habits (per profile)
  // -------------------------
  Future<List<Habit>> loadHabits(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final habitsRaw = prefs.getString(_pkey(profileId, kHabits));

    if (habitsRaw == null) return _seedHabits();

    final list = (jsonDecode(habitsRaw) as List).cast<dynamic>();
    return list.map((e) => Habit.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  Future<void> saveHabits(String profileId, List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pkey(profileId, kHabits),
      jsonEncode(habits.map((e) => e.toJson()).toList()),
    );
  }

  // -------------------------
  // Logs (per profile)
  // -------------------------
  Future<Map<String, DayLog>> loadLogs(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final logsRaw = prefs.getString(_pkey(profileId, kDayLogs));

    if (logsRaw == null) return {};

    final map = (jsonDecode(logsRaw) as Map).cast<String, dynamic>();
    return map.map((k, v) => MapEntry(k, DayLog.fromJson((v as Map).cast<String, dynamic>())));
  }

  Future<void> saveLogs(String profileId, Map<String, DayLog> logsByDate) async {
    final prefs = await SharedPreferences.getInstance();
    final map = logsByDate.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(_pkey(profileId, kDayLogs), jsonEncode(map));
  }

  // -------------------------
  // Funds (per profile)
  // -------------------------
  Future<double> loadFund(String profileId, FundType t) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_pkey(profileId, t.key)) ?? 0;
  }

  Future<void> saveFund(String profileId, FundType t, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_pkey(profileId, t.key), value);
  }

  List<Habit> _seedHabits() => [
        Habit(id: 'h_water', name: 'drink water', points: 1, reasoning: 'baseline care'),
        Habit(id: 'h_walk', name: 'walk (10+ min)', points: 2, reasoning: 'movement helps my brain'),
        Habit(id: 'h_workout', name: 'exercise / workout', points: 4, reasoning: 'big effort', isExercise: true),
        Habit(id: 'h_read', name: 'read (10+ min)', points: 2),
        Habit(id: 'h_cleanup', name: 'tidy space (5 min)', points: 1),
      ];
}
