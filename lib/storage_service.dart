import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'habit.dart';
import 'day_log.dart';
import 'fund_type.dart';

// NEW (v2)
import 'behavior.dart';
import 'goal.dart';

class StorageService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _uid() {
    final u = _auth.currentUser;
    if (u == null) {
      throw StateError('Not signed in. currentUser is null.');
    }
    return u.uid;
  }

  DocumentReference<Map<String, dynamic>> _userDoc() =>
      _db.collection('users').doc(_uid());

  CollectionReference<Map<String, dynamic>> _habitsCol() =>
      _userDoc().collection('habits');

  CollectionReference<Map<String, dynamic>> _logsCol() =>
      _userDoc().collection('dayLogs');

  DocumentReference<Map<String, dynamic>> _fundsDoc() =>
      _userDoc().collection('funds').doc('main');

  // =========================
  // V2: Setup gate + Behaviors
  // =========================

  CollectionReference<Map<String, dynamic>> _behaviorsCol() =>
      _userDoc().collection('behaviors');

  CollectionReference<Map<String, dynamic>> _goalsCol() =>
      _userDoc().collection('goals');

  Future<bool> isSetupComplete() async {
    final snap = await _userDoc().get();
    final data = snap.data();
    if (data == null) return false;
    return (data['setupComplete'] as bool?) ?? false;
  }

  Future<void> setSetupComplete(bool v) async {
    await _userDoc().set({'setupComplete': v}, SetOptions(merge: true));
  }

  Future<void> saveBehaviors(List<Behavior> behaviors) async {
    final batch = _db.batch();

    for (final b in behaviors) {
      batch.set(
        _behaviorsCol().doc(b.id),
        b.toMap(),
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<void> saveGoals(List<Goal> goals) async {
    final batch = _db.batch();

    for (final g in goals) {
      batch.set(
        _goalsCol().doc(g.behaviorId),
        g.toMap(),
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  /// One-call convenience used by the setup wizard.
  Future<void> saveSetupV2({
    required List<Behavior> behaviors,
    required List<Goal> goals,
  }) async {
    final batch = _db.batch();

    // upsert behaviors
    for (final b in behaviors) {
      batch.set(_behaviorsCol().doc(b.id), b.toMap(), SetOptions(merge: true));
    }

    // upsert goals (doc id = behaviorId)
    for (final g in goals) {
      batch.set(_goalsCol().doc(g.behaviorId), g.toMap(), SetOptions(merge: true));
    }

    // mark setup complete
    batch.set(_userDoc(), {'setupComplete': true}, SetOptions(merge: true));

    await batch.commit();
  }

  // -------------------------
  // Habits (per user)
  // -------------------------
  Future<List<Habit>> loadHabits() async {
    final snap = await _habitsCol().get();

    if (snap.docs.isEmpty) {
      // seed defaults on first run for this account
      final seeded = _seedHabits();
      final batch = _db.batch();
      for (final h in seeded) {
        batch.set(_habitsCol().doc(h.id), h.toJson());
      }
      await batch.commit();
      return seeded;
    }

    return snap.docs.map((d) => Habit.fromJson(d.data())).toList();
  }

  Future<void> saveHabits(List<Habit> habits) async {
    final batch = _db.batch();
    for (final h in habits) {
      batch.set(_habitsCol().doc(h.id), h.toJson(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> deleteHabitEverywhere(String habitId) async {
    await _habitsCol().doc(habitId).delete();

    final logsSnap = await _logsCol().get();
    final batch = _db.batch();

    for (final doc in logsSnap.docs) {
      batch.update(doc.reference, {
        'completedHabitIds': FieldValue.arrayRemove([habitId]),
      });
    }

    await batch.commit();
  }

  Future<void> replaceHabits(List<Habit> habits) async {
    final existing = await _habitsCol().get();
    final keepIds = habits.map((h) => h.id).toSet();

    final batch = _db.batch();

    for (final doc in existing.docs) {
      if (!keepIds.contains(doc.id)) {
        batch.delete(doc.reference);
      }
    }

    for (final h in habits) {
      batch.set(_habitsCol().doc(h.id), h.toJson(), SetOptions(merge: true));
    }

    await batch.commit();
  }

  // -------------------------
  // Logs (per user)
  // -------------------------
  Future<Map<String, DayLog>> loadLogs() async {
    final snap = await _logsCol().get();
    final out = <String, DayLog>{};
    for (final d in snap.docs) {
      final log = DayLog.fromJson(d.data());
      out[log.dateKey] = log;
    }
    return out;
  }

  Future<void> saveLogs(Map<String, DayLog> logsByDate) async {
    final batch = _db.batch();
    logsByDate.forEach((dateKey, log) {
      batch.set(_logsCol().doc(dateKey), log.toJson(), SetOptions(merge: true));
    });
    await batch.commit();
  }

  Future<void> upsertDayLog(DayLog log) async {
    await _logsCol().doc(log.dateKey).set(log.toJson(), SetOptions(merge: true));
  }

  // -------------------------
  // Funds (per user)
  // -------------------------
  Future<double> loadFund(FundType t) async {
    final snap = await _fundsDoc().get();
    final data = snap.data();
    if (data == null) return 0;
    final v = data[t.key];
    if (v is num) return v.toDouble();
    return 0;
  }

  Future<void> saveFund(FundType t, double value) async {
    await _fundsDoc().set({t.key: value}, SetOptions(merge: true));
  }

  Future<void> incrementFund(FundType t, double delta) async {
    await _fundsDoc().set(
      {t.key: FieldValue.increment(delta)},
      SetOptions(merge: true),
    );
  }

  // -------------------------
  // Defaults
  // -------------------------
  List<Habit> _seedHabits() => [
        Habit(id: 'h_water', name: 'drink water', points: 1, reasoning: 'baseline care'),
        Habit(id: 'h_walk', name: 'walk (10+ min)', points: 2, reasoning: 'movement helps my brain'),
        Habit(id: 'h_workout', name: 'exercise / workout', points: 4, reasoning: 'big effort', isExercise: true),
        Habit(id: 'h_read', name: 'read (10+ min)', points: 2),
        Habit(id: 'h_cleanup', name: 'tidy space (5 min)', points: 1),
      ];
}
