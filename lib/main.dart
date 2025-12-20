import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const HabitApp());
}

/// ------------------------------
/// Models
/// ------------------------------

class Habit {
  final String id;
  String name;
  int points;
  String? reasoning;
  bool isExercise;

  Habit({
    required this.id,
    required this.name,
    required this.points,
    this.reasoning,
    this.isExercise = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'points': points,
        'reasoning': reasoning,
        'isExercise': isExercise,
      };

  static Habit fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] as String,
        name: json['name'] as String,
        points: (json['points'] as num).toInt(),
        reasoning: json['reasoning'] as String?,
        isExercise: (json['isExercise'] as bool?) ?? false,
      );
}

class DayLog {
  final String dateKey; // YYYY-MM-DD
  String note;
  Set<String> completedHabitIds;

  DayLog({
    required this.dateKey,
    this.note = '',
    Set<String>? completedHabitIds,
  }) : completedHabitIds = completedHabitIds ?? <String>{};

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'note': note,
        'completedHabitIds': completedHabitIds.toList(),
      };

  static DayLog fromJson(Map<String, dynamic> json) => DayLog(
        dateKey: json['dateKey'] as String,
        note: (json['note'] as String?) ?? '',
        completedHabitIds: Set<String>.from(
          (json['completedHabitIds'] as List<dynamic>? ?? const [])
              .map((e) => e as String),
        ),
      );
}

enum FundType { lilTreat, funPurchase, saver }

extension FundTypeX on FundType {
  String get label {
    switch (this) {
      case FundType.lilTreat:
        return 'a lil treat';
      case FundType.funPurchase:
        return 'fun purchase';
      case FundType.saver:
        return 'she’s a saver';
    }
  }

  IconData get icon {
    switch (this) {
      case FundType.lilTreat:
        return Icons.coffee;
      case FundType.funPurchase:
        return Icons.shopping_bag;
      case FundType.saver:
        return Icons.bookmark;
    }
  }

  String get key {
    switch (this) {
      case FundType.lilTreat:
        return 'fund_lilTreat';
      case FundType.funPurchase:
        return 'fund_funPurchase';
      case FundType.saver:
        return 'fund_saver';
    }
  }
}

/// ------------------------------
/// Persistence keys
/// ------------------------------

const _kHabits = 'habits_v1';
const _kDayLogs = 'dayLogs_v1';

/// ------------------------------
/// App
/// ------------------------------

class HabitApp extends StatelessWidget {
  const HabitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "zarin’s habit system",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HabitHome(),
    );
  }
}

class HabitHome extends StatefulWidget {
  const HabitHome({super.key});

  @override
  State<HabitHome> createState() => _HabitHomeState();
}

class _HabitHomeState extends State<HabitHome> {
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
    _loadAll();
  }

  static String _todayKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();

    // Habits
    final habitsRaw = prefs.getString(_kHabits);
    if (habitsRaw == null) {
      // seed with a few defaults so it doesn't start empty
      _habits.addAll(_seedHabits());
    } else {
      final list = (jsonDecode(habitsRaw) as List).cast<dynamic>();
      _habits
        ..clear()
        ..addAll(list.map((e) => Habit.fromJson((e as Map).cast<String, dynamic>())));
    }

    // Logs
    final logsRaw = prefs.getString(_kDayLogs);
    if (logsRaw != null) {
      final map = (jsonDecode(logsRaw) as Map).cast<String, dynamic>();
      _logsByDate
        ..clear()
        ..addAll(map.map((k, v) => MapEntry(k, DayLog.fromJson((v as Map).cast<String, dynamic>()))));
    }

    // Funds
    _fundLilTreat = prefs.getDouble(FundType.lilTreat.key) ?? 0;
    _fundFunPurchase = prefs.getDouble(FundType.funPurchase.key) ?? 0;
    _fundSaver = prefs.getDouble(FundType.saver.key) ?? 0;

    setState(() => _loading = false);
  }

  List<Habit> _seedHabits() {
    // You’ll customize this in the Point Menu tab.
    return [
      Habit(id: 'h_water', name: 'drink water', points: 1, reasoning: 'baseline care'),
      Habit(id: 'h_walk', name: 'walk (10+ min)', points: 2, reasoning: 'movement helps my brain'),
      Habit(id: 'h_workout', name: 'exercise / workout', points: 4, reasoning: 'big effort', isExercise: true),
      Habit(id: 'h_read', name: 'read (10+ min)', points: 2),
      Habit(id: 'h_cleanup', name: 'tidy space (5 min)', points: 1),
    ];
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHabits, jsonEncode(_habits.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _logsByDate.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(_kDayLogs, jsonEncode(map));
  }

  Future<void> _saveFunds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(FundType.lilTreat.key, _fundLilTreat);
    await prefs.setDouble(FundType.funPurchase.key, _fundFunPurchase);
    await prefs.setDouble(FundType.saver.key, _fundSaver);
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
      _PointMenuPage(
        habits: _habits,
        onChanged: () async {
          setState(() {});
          await _saveHabits();
        },
        onDeleteHabit: (id) async {
          setState(() {
            _habits.removeWhere((h) => h.id == id);
            // Remove from all logs too
            for (final log in _logsByDate.values) {
              log.completedHabitIds.remove(id);
            }
          });
          await _saveHabits();
          await _saveLogs();
        },
      ),
      _DailyPage(
        habits: _habits,
        dateKey: _selectedDateKey,
        onPickDate: (key) {
          setState(() => _selectedDateKey = key);
        },
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
          await _saveLogs();
        },
        onNoteChanged: (text) async {
          final log = _currentLog();
          setState(() => log.note = text);
          await _saveLogs();
        },
        onDeposit: (fund, amount) async {
          setState(() {
            _setFundValue(fund, _fundValue(fund) + amount);
          });
          await _saveFunds();
        },
      ),
      _FundsPage(
        fundValue: (t) => _fundValue(t),
        onAdjust: (t, delta) async {
          setState(() {
            _setFundValue(t, (_fundValue(t) + delta).clamp(0, 1e12));
          });
          await _saveFunds();
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("zarin’s habit system"),
      ),
      body: pages[_tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'point menu'),
          NavigationDestination(icon: Icon(Icons.today), label: 'daily'),
          NavigationDestination(icon: Icon(Icons.savings), label: 'funds'),
        ],
      ),
    );
  }
}

/// ------------------------------
/// Point Menu Page
/// ------------------------------

class _PointMenuPage extends StatelessWidget {
  final List<Habit> habits;
  final VoidCallback onChanged;
  final Future<void> Function(String habitId) onDeleteHabit;

  const _PointMenuPage({
    required this.habits,
    required this.onChanged,
    required this.onDeleteHabit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'point menu',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Set point values for habits + exercise based on what motivates you right now.',
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: habits.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final h = habits[i];
                return ListTile(
                  title: Text(h.name),
                  subtitle: Text(
                    [
                      '${h.points} pts',
                      if (h.isExercise) 'exercise',
                      if ((h.reasoning ?? '').trim().isNotEmpty) '“${h.reasoning}”',
                    ].join(' • '),
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        tooltip: 'edit',
                        onPressed: () async {
                          await _editHabitDialog(context, h);
                          onChanged();
                        },
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        tooltip: 'delete',
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete habit?'),
                              content: Text('Delete “${h.name}” everywhere?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await onDeleteHabit(h.id);
                          }
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final newHabit = Habit(
                  id: 'h_${DateTime.now().microsecondsSinceEpoch}',
                  name: 'new habit',
                  points: 1,
                );
                habits.add(newHabit);
                await _editHabitDialog(context, newHabit);
                onChanged();
              },
              icon: const Icon(Icons.add),
              label: const Text('add habit'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editHabitDialog(BuildContext context, Habit habit) async {
    final nameCtrl = TextEditingController(text: habit.name);
    final ptsCtrl = TextEditingController(text: habit.points.toString());
    final reasonCtrl = TextEditingController(text: habit.reasoning ?? '');
    bool isExercise = habit.isExercise;

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit habit'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'name'),
              ),
              TextField(
                controller: ptsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'points'),
              ),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'reasoning (optional)'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: isExercise,
                onChanged: (v) => isExercise = v,
                title: const Text('mark as exercise'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('done')),
        ],
      ),
    );

    habit.name = nameCtrl.text.trim().isEmpty ? habit.name : nameCtrl.text.trim();
    final parsed = int.tryParse(ptsCtrl.text.trim());
    if (parsed != null) habit.points = parsed;
    habit.reasoning = reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim();
    habit.isExercise = isExercise;
  }
}

/// ------------------------------
/// Daily Page
/// ------------------------------

class _DailyPage extends StatelessWidget {
  final List<Habit> habits;
  final String dateKey;
  final void Function(String newDateKey) onPickDate;

  final DayLog log;
  final int earnedPoints;

  final Future<void> Function(String habitId, bool checked) onToggleHabit;
  final Future<void> Function(String note) onNoteChanged;
  final Future<void> Function(FundType fund, double amount) onDeposit;

  const _DailyPage({
    required this.habits,
    required this.dateKey,
    required this.onPickDate,
    required this.log,
    required this.earnedPoints,
    required this.onToggleHabit,
    required this.onNoteChanged,
    required this.onDeposit,
  });

  @override
  Widget build(BuildContext context) {
    final earnedDollars = earnedPoints.toDouble(); // 1 point == $1 in v1

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final left = _dailyLeft(context, earnedDollars);
          final right = _dailyRight(context);

          return isWide
    ? Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left can be tall too, so make it scrollable as well
          Expanded(
            child: SingleChildScrollView(
              child: left,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: right,
            ),
          ),
        ],
      )
    : ListView(
        children: [
          left,
          const SizedBox(height: 16),
          right,
        ],
      );

        },
      ),
    );
  }

  Widget _dailyLeft(BuildContext context, double earnedDollars) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dateRow(context),
            const SizedBox(height: 12),
            Text(
              'today earned: \$${earnedDollars.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text('daily note'),
            const SizedBox(height: 8),
            TextField(
              maxLines: 4,
              controller: TextEditingController(text: log.note),
              onChanged: (v) => onNoteChanged(v),
              decoration: const InputDecoration(
                hintText: 'a few words… or a full rant…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('habits completed'),
            const SizedBox(height: 8),
            ...habits.map((h) {
              final checked = log.completedHabitIds.contains(h.id);
              return CheckboxListTile(
                value: checked,
                onChanged: (v) => onToggleHabit(h.id, v ?? false),
                title: Text(h.name),
                subtitle: Text('${h.points} pts${h.isExercise ? ' • exercise' : ''}'),
                controlAffinity: ListTileControlAffinity.leading,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _dailyRight(BuildContext context) {
    final earnedDollars = earnedPoints.toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('deposit today’s earnings'),
            const SizedBox(height: 8),
            Text(
              'available to deposit: \$${earnedDollars.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _fundDepositButton(context, FundType.lilTreat, earnedDollars),
            const SizedBox(height: 8),
            _fundDepositButton(context, FundType.funPurchase, earnedDollars),
            const SizedBox(height: 8),
            _fundDepositButton(context, FundType.saver, earnedDollars),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'v1 notes',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              '• v1 uses 1 point = \$1\n'
              '• you can add multipliers/bonuses later\n'
              '• funds live in your browser storage',
            ),
          ],
        ),
      ),
    );
  }

  Widget _fundDepositButton(BuildContext context, FundType fund, double amount) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: amount <= 0
            ? null
            : () async {
                // In v1 we don't “deduct” from available because we haven't implemented
                // a strict accounting of daily earnings vs deposits (easy add later).
                await onDeposit(fund, amount);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('deposited \$${amount.toStringAsFixed(0)} into ${fund.label}')),
                );
              },
        icon: Icon(fund.icon),
        label: Text('deposit into ${fund.label}'),
      ),
    );
  }

  Widget _dateRow(BuildContext context) {
    return Row(
      children: [
        Text(
          dateKey,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: () async {
            final now = DateTime.now();
            final initial = DateTime.tryParse(dateKey) ?? now;
            final picked = await showDatePicker(
              context: context,
              firstDate: DateTime(now.year - 2),
              lastDate: DateTime(now.year + 2),
              initialDate: initial,
            );
            if (picked != null) {
              final y = picked.year.toString().padLeft(4, '0');
              final m = picked.month.toString().padLeft(2, '0');
              final d = picked.day.toString().padLeft(2, '0');
              onPickDate('$y-$m-$d');
            }
          },
          icon: const Icon(Icons.calendar_month),
          label: const Text('pick date'),
        ),
      ],
    );
  }
}

/// ------------------------------
/// Funds Page
/// ------------------------------

class _FundsPage extends StatelessWidget {
  final double Function(FundType) fundValue;
  final Future<void> Function(FundType, double delta) onAdjust;

  const _FundsPage({
    required this.fundValue,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    Widget card(FundType t, String description) {
      final v = fundValue(t);
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(t.icon),
                  const SizedBox(width: 8),
                  Text(
                    t.label,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(description),
              const SizedBox(height: 12),
              Text(
                '\$${v.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _spendDialog(context, t),
                    icon: const Icon(Icons.remove),
                    label: const Text('spend'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _addDialog(context, t),
                    icon: const Icon(Icons.add),
                    label: const Text('add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        card(
          FundType.lilTreat,
          'coffee, croissants, lil snacks, movie solo — spend pretty quickly.',
        ),
        card(
          FundType.funPurchase,
          'save up for a fun want (new shoes, skincare, class, etc).',
        ),
        card(
          FundType.saver,
          'big life stuff: trips, house, wedding, “i’ll be rich eventually” energy.',
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'Tip: funds are saved in your browser (localStorage) automatically.',
          ),
        ),
      ],
    );
  }

  Future<void> _addDialog(BuildContext context, FundType t) async {
    final ctrl = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add to ${t.label}'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'amount',
            hintText: 'e.g. 3.50',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('cancel')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim());
              Navigator.pop(context, v);
            },
            child: const Text('add'),
          ),
        ],
      ),
    );

    if (amount != null && amount > 0) {
      await onAdjust(t, amount);
    }
  }

  Future<void> _spendDialog(BuildContext context, FundType t) async {
    final ctrl = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Spend from ${t.label}'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'amount',
            hintText: 'e.g. 6.00',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('cancel')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim());
              Navigator.pop(context, v);
            },
            child: const Text('spend'),
          ),
        ],
      ),
    );

    if (amount != null && amount > 0) {
      await onAdjust(t, -amount);
    }
  }
}
