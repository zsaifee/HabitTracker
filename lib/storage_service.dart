// ==============================
// storage_service.dart
// ==============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'habit.dart';
import 'day_log.dart';
import 'fund_type.dart';

import 'behavior.dart';
import 'goal.dart';
import 'category_type.dart';

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

  // V2
  CollectionReference<Map<String, dynamic>> _behaviorsCol() =>
      _userDoc().collection('behaviors');

  CollectionReference<Map<String, dynamic>> _goalsCol() =>
      _userDoc().collection('goals');

  // =========================
  // Setup gate
  // =========================

  Future<bool> isSetupComplete() async {
    final snap = await _userDoc().get();
    final data = snap.data();
    if (data == null) return false;
    return (data['setupComplete'] as bool?) ?? false;
  }

  Future<void> setSetupComplete(bool v) async {
    await _userDoc().set({'setupComplete': v}, SetOptions(merge: true));
  }

  // =========================
  // V2 save
  // =========================

  Future<void> saveSetupV2({
    required List<Behavior> behaviors,
    required List<Goal> goals,
  }) async {
    final batch = _db.batch();

    // wipe existing habits so defaults disappear
    final oldHabits = await _habitsCol().get();
    for (final d in oldHabits.docs) {
      batch.delete(d.reference);
    }

    // wipe existing goals (setup is source of truth)
    final oldGoals = await _goalsCol().get();
    for (final d in oldGoals.docs) {
      batch.delete(d.reference);
    }

    // upsert behaviors + mirror into habits
    for (final b in behaviors) {
      // behaviors
      batch.set(_behaviorsCol().doc(b.id), b.toMap(), SetOptions(merge: true));

      // habits mirror for the rest of the app
      batch.set(
        _habitsCol().doc(b.id),
        Habit(
          id: b.id,
          name: b.name,
          points: 1,
          category: b.category,
          rank: b.rank,
          isExercise: false,
          reasoning: null,
        ).toJson(),
        SetOptions(merge: true),
      );
    }

    // upsert goals (doc id = behaviorId)
    for (final g in goals) {
      batch.set(
        _goalsCol().doc(g.behaviorId),
        g.toMap(),
        SetOptions(merge: true),
      );
    }

    // mark setup complete
    batch.set(_userDoc(), {'setupComplete': true}, SetOptions(merge: true));

    await batch.commit();
  }

  // =========================
  // Habits
  // =========================

  Future<List<Habit>> loadHabits() async {
    final snap = await _habitsCol().get();

    if (snap.docs.isNotEmpty) {
      final habits =
          snap.docs.map((d) => Habit.fromDoc(d.id, d.data())).toList();
      habits.sort((a, b) {
        final c = a.category.key.compareTo(b.category.key);
        if (c != 0) return c;
        return a.rank.compareTo(b.rank);
      });
      return habits;
    }

    // No habits yet: seed defaults ONLY if setup isn't complete.
    final setupDone = await isSetupComplete();
    if (!setupDone) {
      final seeded = _seedHabits();
      final batch = _db.batch();
      for (final h in seeded) {
        batch.set(_habitsCol().doc(h.id), h.toJson());
      }
      await batch.commit();
      return seeded;
    }

    // Setup complete but habits empty: rebuild from behaviors (recovery)
    final behaviorsSnap = await _behaviorsCol().get();
    if (behaviorsSnap.docs.isEmpty) return <Habit>[];

    final batch = _db.batch();
    final out = <Habit>[];

    for (final d in behaviorsSnap.docs) {
      final b = Behavior.fromDoc(d.id, d.data());
      final h = Habit(
        id: b.id,
        name: b.name,
        points: 1,
        category: b.category,
        rank: b.rank,
      );

      batch.set(_habitsCol().doc(h.id), h.toJson(), SetOptions(merge: true));
      out.add(h);
    }

    await batch.commit();

    out.sort((a, b) {
      final c = a.category.key.compareTo(b.category.key);
      if (c != 0) return c;
      return a.rank.compareTo(b.rank);
    });

    return out;
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

  // =========================
  // Logs
  // =========================

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
    await _logsCol()
        .doc(log.dateKey)
        .set(log.toJson(), SetOptions(merge: true));
  }

  // =========================
  // Funds
  // =========================

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

  // =========================
  // Defaults (KEEP YOUR EXISTING)
  // =========================

  List<Habit> _seedHabits() {
    // IMPORTANT:
    // Replace with your real defaults list if you still want defaults before setup.
    // If you *never* want defaults, just return [].
    return <Habit>[];
  }

  Future<bool> isOnboardingComplete() async {
  final snap = await _userDoc().get();
  final data = snap.data();
  if (data == null) return false;
  return (data['onboardingComplete'] as bool?) ?? false;
}

Future<void> setOnboardingComplete(bool v) async {
  await _userDoc().set({'onboardingComplete': v}, SetOptions(merge: true));
}


  // =========================
  // Fun Purchase Goal (stored in funds/main)
  // =========================

  Future<({String name, double price})> loadFunPurchaseGoal() async {
    final snap = await _fundsDoc().get();
    final data = snap.data();
    if (data == null) return (name: '', price: 0.0);

    final rawName = data['funGoalName'];
    final rawPrice = data['funGoalPrice'];

    final name = rawName is String ? rawName : '';
    final price = rawPrice is num ? rawPrice.toDouble() : 0.0;

    return (name: name, price: price);
  }

  Future<void> saveFunPurchaseGoal({
    required String name,
    required double price,
  }) async {
    await _fundsDoc().set(
      {
        'funGoalName': name,
        'funGoalPrice': price,
      },
      SetOptions(merge: true),
    );
  }

    // =========================
  // Fun Purchase Goals (stored in funds/main)
  // =========================

  Future<List<Map<String, dynamic>>> loadFunPurchaseGoalsRaw() async {
    final snap = await _fundsDoc().get();
    final data = snap.data();
    if (data == null) return <Map<String, dynamic>>[];

    final raw = data['funGoals'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> saveFunPurchaseGoalsRaw(List<Map<String, dynamic>> goals) async {
    await _fundsDoc().set(
      {'funGoals': goals},
      SetOptions(merge: true),
    );
  }
}
