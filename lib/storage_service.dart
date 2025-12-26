import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'habit.dart';
import 'day_log.dart';
import 'fund_type.dart';

class StorageService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // -------------------------
  // Auth / base refs
  // -------------------------
  Future<String> _uid() async {
    final current = _auth.currentUser;
    if (current != null) return current.uid;

    final cred = await _auth.signInAnonymously();
    return cred.user!.uid;
  }

  Future<DocumentReference<Map<String, dynamic>>> _userDoc() async {
    final uid = await _uid();
    return _db.collection('users').doc(uid);
  }

  Future<CollectionReference<Map<String, dynamic>>> _habitsCol() async {
    final user = await _userDoc();
    return user.collection('habits');
  }

  Future<CollectionReference<Map<String, dynamic>>> _logsCol() async {
    final user = await _userDoc();
    return user.collection('dayLogs');
  }

  Future<DocumentReference<Map<String, dynamic>>> _fundsDoc() async {
    final user = await _userDoc();
    return user.collection('funds').doc('main');
  }

  // -------------------------
  // Onboarding (V2 setup flow)
  // -------------------------
  Future<void> ensureUserInitialized() async {
    final doc = await _userDoc();
    final snap = await doc.get();

    if (!snap.exists) {
      await doc.set({
        'createdAt': FieldValue.serverTimestamp(),
        'onboardingDone': false,
      }, SetOptions(merge: true));
      return;
    }

    final data = snap.data();
    if (data == null || !data.containsKey('onboardingDone')) {
      await doc.set({'onboardingDone': false}, SetOptions(merge: true));
    }
  }

  Future<bool> getOnboardingDone() async {
    final doc = await _userDoc();
    final snap = await doc.get();
    final data = snap.data();
    return (data?['onboardingDone'] as bool?) ?? false;
  }

  Future<void> setOnboardingDone(bool done) async {
    final doc = await _userDoc();
    await doc.set({'onboardingDone': done}, SetOptions(merge: true));
  }

  Future<void> setWishlistItems(List<Map<String, dynamic>> items) async {
    final doc = await _userDoc();
    await doc.set({'wishlist': items}, SetOptions(merge: true));
  }

  /// Creates the first habit from onboarding.
  /// NOTE: Your Habit model does not currently have fundType, so we store fundTypeKey in `reasoning`
  /// as a lightweight workaround. If you later add a real field, we can migrate it cleanly.
  Future<void> createHabitFromOnboarding({
    required String name,
    required String fundTypeKey, // "lilTreat" or "funPurchase"
    required double value,
  }) async {
    final habits = await _habitsCol();

    // Your Habit uses int points. Onboarding value is dollars (double).
    // Best simple mapping: round to nearest int, min 0.
    final points = value.isNaN ? 0 : value.round().clamp(0, 999999);

    final id = habits.doc().id;

    final habit = Habit(
      id: id,
      name: name.trim(),
      points: points,
      reasoning: 'fund:$fundTypeKey',
    );

    await habits.doc(id).set(habit.toJson(), SetOptions(merge: true));
  }

  // -------------------------
  // Habits (per user)
  // -------------------------
  Future<List<Habit>> loadHabits() async {
    final habits = await _habitsCol();
    final snap = await habits.get();

    if (snap.docs.isEmpty) {
      // seed defaults on first run for this account
      final seeded = _seedHabits();
      final batch = _db.batch();
      for (final h in seeded) {
        batch.set(habits.doc(h.id), h.toJson());
      }
      await batch.commit();
      return seeded;
    }

    return snap.docs.map((d) => Habit.fromJson(d.data())).toList();
  }

  Future<void> saveHabits(List<Habit> habitsList) async {
    // Upsert everything you pass in. (Does not delete missing habits.)
    final habits = await _habitsCol();
    final batch = _db.batch();
    for (final h in habitsList) {
      batch.set(habits.doc(h.id), h.toJson(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> deleteHabitEverywhere(String habitId) async {
    final habits = await _habitsCol();
    final logs = await _logsCol();

    await habits.doc(habitId).delete();

    final logsSnap = await logs.get();
    final batch = _db.batch();

    for (final doc in logsSnap.docs) {
      batch.update(doc.reference, {
        'completedHabitIds': FieldValue.arrayRemove([habitId]),
      });
    }

    await batch.commit();
  }

  Future<void> replaceHabits(List<Habit> habitsList) async {
    final habits = await _habitsCol();
    final existing = await habits.get();
    final keepIds = habitsList.map((h) => h.id).toSet();

    final batch = _db.batch();

    // delete docs not in the new list
    for (final doc in existing.docs) {
      if (!keepIds.contains(doc.id)) {
        batch.delete(doc.reference);
      }
    }

    // upsert new list
    for (final h in habitsList) {
      batch.set(habits.doc(h.id), h.toJson(), SetOptions(merge: true));
    }

    await batch.commit();
  }

  // -------------------------
  // Logs (per user)
  // -------------------------
  Future<Map<String, DayLog>> loadLogs() async {
    final logs = await _logsCol();
    final snap = await logs.get();
    final out = <String, DayLog>{};

    for (final d in snap.docs) {
      final log = DayLog.fromJson(d.data());
      out[log.dateKey] = log;
    }
    return out;
  }

  Future<void> saveLogs(Map<String, DayLog> logsByDate) async {
    final logs = await _logsCol();
    final batch = _db.batch();

    logsByDate.forEach((dateKey, log) {
      batch.set(logs.doc(dateKey), log.toJson(), SetOptions(merge: true));
    });

    await batch.commit();
  }

  Future<void> upsertDayLog(DayLog log) async {
    final logs = await _logsCol();
    await logs.doc(log.dateKey).set(log.toJson(), SetOptions(merge: true));
  }

  // -------------------------
  // Funds (per user)
  // -------------------------
  Future<double> loadFund(FundType t) async {
    final funds = await _fundsDoc();
    final snap = await funds.get();
    final data = snap.data();
    if (data == null) return 0;

    final v = data[t.key];
    if (v is num) return v.toDouble();
    return 0;
  }

  Future<void> saveFund(FundType t, double value) async {
    final funds = await _fundsDoc();
    await funds.set({t.key: value}, SetOptions(merge: true));
  }

  Future<void> incrementFund(FundType t, double delta) async {
    final funds = await _fundsDoc();
    await funds.set(
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
