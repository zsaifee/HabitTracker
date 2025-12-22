import 'package:flutter/material.dart';

import 'app_style.dart';
import 'habit.dart';
import 'fund_type.dart';
import 'day_log.dart';

import 'point_menu.dart';
import 'daily.dart';
import 'funds.dart';
import 'storage_service.dart';

class HabitHome extends StatefulWidget {
  const HabitHome({super.key});

  @override
  State<HabitHome> createState() => _HabitHomeState();
}

class _HabitHomeState extends State<HabitHome> {
  late final StorageService _storage;

  int _tabIndex = 0;

  final List<Habit> _habits = [];
  final Map<String, DayLog> _logsByDate = {}; // dateKey -> DayLog

  double _fundLilTreat = 0;
  double _fundFunPurchase = 0;
  double _fundSaver = 0;

  String _selectedDateKey = _todayKey();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _storage = StorageService();
    _loadAll();
  }

  static String _todayKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _loadAll() async {
    final habits = await _storage.loadHabits();
    final logs = await _storage.loadLogs();

    final lil = await _storage.loadFund(FundType.lilTreat);
    final fun = await _storage.loadFund(FundType.funPurchase);
    final sav = await _storage.loadFund(FundType.saver);

    setState(() {
      _habits
        ..clear()
        ..addAll(habits);

      _logsByDate
        ..clear()
        ..addAll(logs);

      _fundLilTreat = lil;
      _fundFunPurchase = fun;
      _fundSaver = sav;

      _loading = false;
    });
  }

  DayLog _currentLog() {
    return _logsByDate.putIfAbsent(_selectedDateKey, () => DayLog(dateKey: _selectedDateKey));
  }

  int _earnedPointsForLog(DayLog log) {
    final habitMap = {for (final h in _habits) h.id: h};
    int sum = 0;
    for (final id in log.completedHabitIds) {
      final h = habitMap[id];
      if (h != null) sum += h.points;
    }
    return sum;
  }

  double _fundValue(FundType t) {
    switch (t) {
      case FundType.lilTreat:
        return _fundLilTreat;
      case FundType.funPurchase:
        return _fundFunPurchase;
      case FundType.saver:
        return _fundSaver;
    }
  }

  void _setFundValue(FundType t, double v) {
    switch (t) {
      case FundType.lilTreat:
        _fundLilTreat = v;
        break;
      case FundType.funPurchase:
        _fundFunPurchase = v;
        break;
      case FundType.saver:
        _fundSaver = v;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = [
      PointMenuPage(
        habits: _habits,
        onChanged: () async {
          setState(() {});
          await _storage.saveHabits(_habits);
        },
        onDeleteHabit: (id) async {
          setState(() {
            _habits.removeWhere((h) => h.id == id);
            for (final log in _logsByDate.values) {
              log.completedHabitIds.remove(id);
            }
          });
          await _storage.saveHabits(_habits);
          await _storage.saveLogs(_logsByDate);
        },
      ),
      DailyPage(
        habits: _habits,
        dateKey: _selectedDateKey,
        onPickDate: (key) => setState(() => _selectedDateKey = key),
        log: _currentLog(),
        earnedPoints: _earnedPointsForLog(_currentLog()),
        onToggleHabit: (habitId, checked) async {
          final log = _currentLog();
          setState(() {
            if (checked) {
              log.completedHabitIds.add(habitId);
            } else {
              log.completedHabitIds.remove(habitId);
            }
          });
          await _storage.saveLogs(_logsByDate);
        },
        onNoteChanged: (text) async {
          final log = _currentLog();
          setState(() => log.note = text);
          await _storage.saveLogs(_logsByDate);
        },
        onDeposit: (fund, amount) async {
          setState(() => _setFundValue(fund, _fundValue(fund) + amount));
          await _storage.saveFund(fund, _fundValue(fund));
        },
      ),
      FundsPage(
        fundValue: (t) => _fundValue(t),
        onAdjust: (t, delta) async {
          setState(() => _setFundValue(t, (_fundValue(t) + delta).clamp(0, 1e12)));
          await _storage.saveFund(t, _fundValue(t));
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("the ultimate habit system"),
        centerTitle: false,
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppStyle.headerGradient(context),
          ),
        ),
      ),
      body: pages[_tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'menu ✎'),
          NavigationDestination(icon: Icon(Icons.today), label: 'today ✨'),
          NavigationDestination(icon: Icon(Icons.savings), label: 'funds 💸'),
        ],
      ),
    );
  }
}
