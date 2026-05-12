// daily.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_style.dart';
import 'habit.dart';
import 'fund_type.dart';
import 'day_log.dart';
import 'category_type.dart';

class DailyPage extends StatefulWidget {
  final List<Habit> habits;
  final String dateKey;
  final void Function(String newDateKey) onPickDate;

  final DayLog log;
  final int earnedPoints;

  final Future<void> Function(String habitId, bool checked) onToggleHabit;
  final Future<void> Function(String note) onNoteChanged;
  final Future<void> Function(FundType fund, double amount) onDeposit;
  final Future<void> Function(String habitId) onDeleteHabit;
  final Future<void> Function() onHabitsChanged;

  const DailyPage({
    super.key,
    required this.habits,
    required this.dateKey,
    required this.onPickDate,
    required this.log,
    required this.earnedPoints,
    required this.onToggleHabit,
    required this.onNoteChanged,
    required this.onDeposit,
    required this.onHabitsChanged,
    required this.onDeleteHabit,
  });

  @override
  State<DailyPage> createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> {
  String _formattedDate(String dateKey) {
    final date = DateTime.parse(dateKey);
    return DateFormat('EEE, MMM d').format(date).toLowerCase();
  }

  int _nextRankFor(CategoryType cat, {String? excludeId}) {
    final maxRank = widget.habits
        .where(
          (h) =>
              h.category == cat &&
              (excludeId == null || h.id != excludeId),
        )
        .fold<int>(
          0,
          (m, h) => h.rank > m ? h.rank : m,
        );

    return maxRank + 1;
  }

  int _defaultDollars(CategoryType c) =>
      Habit.defaultPointsForCategory(c);

  int _clampDollars(int v) =>
      Habit.clampPoints(v);

  Map<CategoryType, List<Habit>> _groupedHabits() {
    final grouped = <CategoryType, List<Habit>>{
      for (final c in CategoryType.values) c: <Habit>[],
    };

    for (final h in widget.habits) {
      grouped[h.category]?.add(h);
    }

    for (final c in grouped.keys) {
      grouped[c]!
          .sort((a, b) => a.rank.compareTo(b.rank));
    }

    grouped.removeWhere(
      (key, value) => value.isEmpty,
    );

    return grouped;
  }

  DateTime? _tryGetDeadline(Habit habit) {
    try {
      final dynamic h = habit;

      final dynamic rawDeadline =
          h.deadline ??
          h.dueDate ??
          h.deadlineDate;

      if (rawDeadline == null) return null;

      if (rawDeadline is DateTime) {
        return rawDeadline;
      }

      if (rawDeadline is String) {
        return DateTime.tryParse(rawDeadline);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  List<Habit> _urgentHabits() {
    final today = DateTime.now();

    return widget.habits.where((habit) {
      final deadline = _tryGetDeadline(habit);

      if (deadline == null) return false;

      final daysAway =
          deadline.difference(today).inDays;

      final completed = widget
          .log.completedHabitIds
          .contains(habit.id);

      return !completed &&
          daysAway >= 0 &&
          daysAway <= 3;
    }).toList();
  }

  Future<void> _addBasicHabit(
    BuildContext context,
  ) async {
    final defaultCat = CategoryType.daily;

    final newHabit = Habit(
      id:
          'h_${DateTime.now().microsecondsSinceEpoch}',
      name: 'new habit',
      points: 1,
      category: defaultCat,
      rank: _nextRankFor(defaultCat),
    );

    widget.habits.add(newHabit);

    await _editHabitDialog(
      context,
      newHabit,
      simpleMode: true,
    );

    await widget.onHabitsChanged();

    if (mounted) setState(() {});
  }

  Future<void> _addCustomHabit(
    BuildContext context,
  ) async {
    final defaultCat = CategoryType.custom;

    final newHabit = Habit(
      id:
          'h_${DateTime.now().microsecondsSinceEpoch}',
      name: 'new habit',
      points: _defaultDollars(defaultCat),
      category: defaultCat,
      rank: _nextRankFor(defaultCat),
    );

    widget.habits.add(newHabit);

    await _editHabitDialog(
      context,
      newHabit,
    );

    await widget.onHabitsChanged();

    if (mounted) setState(() {});
  }

  Future<void> _editHabitDialog(
  BuildContext context,
  Habit habit, {
  bool simpleMode = false,
}) async {
  final nameCtrl = TextEditingController(text: habit.name);

  CategoryType selectedCat = habit.category;
  int dollars = _clampDollars(habit.points);

  final basicCategories = [
    CategoryType.daily,
    CategoryType.weekly,
    CategoryType.monthly,
  ];

  if (simpleMode && !basicCategories.contains(selectedCat)) {
    selectedCat = CategoryType.daily;
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(simpleMode ? 'add basic habit' : 'add custom habit'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'name',
                    labelStyle: TextStyle(height: 1.8),
                  ),
                ),

                const SizedBox(height: 20),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'dollars: \$$dollars',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),

                Slider(
                  value: dollars.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '\$$dollars',
                  onChanged: (v) {
                    setDialogState(() {
                      dollars = v.round();
                    });
                  },
                ),

                if (simpleMode) ...[
                  const SizedBox(height: 20),

                  DropdownButtonFormField<CategoryType>(
                    initialValue: selectedCat,
                    decoration: const InputDecoration(
                      labelText: 'frequency',
                    ),
                    items: [
                      for (final c in basicCategories)
                        DropdownMenuItem(
                          value: c,
                          child: Text(c.title),
                        ),
                    ],
                    onChanged: (c) {
                      if (c == null) return;

                      setDialogState(() {
                        selectedCat = c;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final newName = nameCtrl.text.trim();

                if (newName.isEmpty) {
                  widget.habits.removeWhere((h) => h.id == habit.id);
                }

                Navigator.pop(dialogContext);
              },
              child: const Text('cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('save'),
            ),
          ],
        ),
      );
    },
  );

  final newName = nameCtrl.text.trim();
  if (newName.isEmpty) return;

  habit.name = newName;
  habit.points = _clampDollars(dollars);
  habit.category = selectedCat;
  habit.rank = _nextRankFor(selectedCat, excludeId: habit.id);
  habit.reasoning = null;
  habit.isExercise = false;
}

  @override
  Widget build(BuildContext context) {
    final earnedDollars =
        widget.earnedPoints.toDouble();

    return Container(
      decoration: BoxDecoration(
        gradient: AppStyle.pageWash(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide =
                constraints.maxWidth >= 900;

            final left =
                _dailyMain(
              context,
              earnedDollars,
            );

            final right =
                _quickLookPanel(
              context,
              earnedDollars,
            );

            return isWide
                ? Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Expanded(
                        child:
                            SingleChildScrollView(
                          child: left,
                        ),
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      SizedBox(
                        width: 380,
                        child:
                            SingleChildScrollView(
                          child: right,
                        ),
                      ),
                    ],
                  )
                : ListView(
                    children: [
                      left,
                      const SizedBox(
                        height: 16,
                      ),
                      right,
                    ],
                  );
          },
        ),
      ),
    );
  }

  Widget _dailyMain(
    BuildContext context,
    double earnedDollars,
  ) {
    final grouped =
        _groupedHabits();

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _dateRow(context),

            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment:
                  WrapCrossAlignment
                      .center,
              children: [
                Text(
                  'today',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontSize: 26,
                      ),
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFEDE9FF,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      999,
                    ),
                    border: Border.all(
                      color:
                          const Color(
                        0xFFD7CFFF,
                      ),
                    ),
                  ),
                  child: Text(
                    'earned \$${earnedDollars.toStringAsFixed(0)}',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                const Text(
                  'habits',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const Spacer(),

                FilledButton.icon(
                  onPressed: () =>
                      _addBasicHabit(
                    context,
                  ),
                  icon: const Icon(
                    Icons.add,
                  ),
                  label:
                      const Text('basic'),
                ),

                const SizedBox(width: 8),

                OutlinedButton.icon(
                  onPressed: () =>
                      _addCustomHabit(
                    context,
                  ),
                  icon: const Icon(
                    Icons.tune,
                  ),
                  label:
                      const Text('custom'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (grouped.isEmpty)
              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 20,
                ),
                child:
                    Text('no habits yet'),
              )
            else
              ...grouped.entries.map(
                (entry) {
                  return _habitCategorySection(
                    context,
                    entry.key.title,
                    entry.value,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _habitCategorySection(
    BuildContext context,
    String title,
    List<Habit> habits,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 18,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title.toLowerCase(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          ...habits.map((h) {
            final checked = widget
                .log.completedHabitIds
                .contains(h.id);

            return Card(
              margin:
                  const EdgeInsets.symmetric(
                vertical: 4,
              ),
              child: CheckboxListTile(
                value: checked,
                onChanged: (v) =>
                    widget.onToggleHabit(
                  h.id,
                  v ?? false,
                ),
                title: Text(h.name),
                subtitle: Text(
                  '\$${h.points}',
                ),
                controlAffinity:
                    ListTileControlAffinity
                        .leading,
                secondary: IconButton(
                  tooltip:
                      'delete habit',
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                  onPressed:
                      () async {
                    final ok =
                        await showDialog<
                            bool>(
                      context:
                          context,
                      builder:
                          (_) =>
                              AlertDialog(
                        title: const Text(
                          'delete habit?',
                        ),
                        content:
                            Text(
                          'delete “${h.name}” everywhere?',
                        ),
                        actions: [
                          TextButton(
                            onPressed:
                                () => Navigator.pop(
                              context,
                              false,
                            ),
                            child: const Text(
                              'cancel',
                            ),
                          ),
                          FilledButton(
                            onPressed:
                                () => Navigator.pop(
                              context,
                              true,
                            ),
                            child: const Text(
                              'delete',
                            ),
                          ),
                        ],
                      ),
                    );

                    if (ok == true) {
                      await widget
                          .onDeleteHabit(
                        h.id,
                      );

                      if (mounted) {
                        setState(() {});
                      }
                    }
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _quickLookPanel(
    BuildContext context,
    double earnedDollars,
  ) {
    final urgent =
        _urgentHabits();

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'quick look',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.w900,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'urgent',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            if (urgent.isEmpty)
              const Text(
                'nothing urgent right now',
                style: TextStyle(
                  color: Colors.black54,
                ),
              )
            else
              ...urgent.map((h) {
                final deadline =
                    _tryGetDeadline(h);

                final deadlineText =
                    deadline == null
                        ? ''
                        : 'due ${DateFormat('MMM d').format(deadline).toLowerCase()}';

                return ListTile(
                  dense: true,
                  contentPadding:
                      EdgeInsets.zero,
                  leading: const Icon(
                    Icons.priority_high,
                  ),
                  title: Text(h.name),
                  subtitle:
                      Text(deadlineText),
                );
              }),

            const SizedBox(height: 18),

            const Divider(),

            const SizedBox(height: 12),

            const Text(
              'funds',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'available to deposit: \$${earnedDollars.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            _fundDepositButton(
              context,
              FundType.lilTreat,
              earnedDollars,
            ),

            const SizedBox(height: 8),

            _fundDepositButton(
              context,
              FundType.funPurchase,
              earnedDollars,
            ),
          ],
        ),
      ),
    );
  }

  Widget _fundDepositButton(
    BuildContext context,
    FundType fund,
    double amount,
  ) {
    final fundColor =
        AppStyle.fundColor(fund);

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: fundColor,
          foregroundColor:
              Colors.black87,
        ),
        onPressed:
            amount <= 0
                ? null
                : () async {
                    final messenger =
                        ScaffoldMessenger.of(
                      context,
                    );

                    final toClear = widget
                        .log
                        .completedHabitIds
                        .toList(
                          growable: false,
                        );

                    try {
                      await widget
                          .onDeposit(
                        fund,
                        amount,
                      );

                      if (!mounted) {
                        return;
                      }

                      await Future.wait(
                        toClear.map(
                          (id) => widget
                              .onToggleHabit(
                            id,
                            false,
                          ),
                        ),
                      );

                      if (!mounted) {
                        return;
                      }

                      messenger.showSnackBar(
                        SnackBar(
                          behavior:
                              SnackBarBehavior
                                  .floating,
                          backgroundColor:
                              Colors.black87,
                          content: Text(
                            'deposited \$${amount.toStringAsFixed(0)} into ${fund.label}',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) {
                        return;
                      }

                      messenger.showSnackBar(
                        SnackBar(
                          behavior:
                              SnackBarBehavior
                                  .floating,
                          backgroundColor:
                              Colors.black87,
                          content: Text(
                            'deposit failed: $e',
                          ),
                        ),
                      );
                    }
                  },
        icon: Icon(fund.icon),
        label: Text(
          'deposit into ${fund.label}',
        ),
      ),
    );
  }

  Widget _dateRow(
    BuildContext context,
  ) {
    return Row(
      children: [
        Text(
          _formattedDate(
            widget.dateKey,
          ),
          style: const TextStyle(
            fontSize: 16,
            fontWeight:
                FontWeight.w800,
          ),
        ),

        const Spacer(),

        OutlinedButton.icon(
          onPressed: () async {
            final now = DateTime.now();

            final initial =
                DateTime.tryParse(
                      widget.dateKey,
                    ) ??
                    now;

            final picked =
                await showDatePicker(
              context: context,
              firstDate: DateTime(
                now.year - 2,
              ),
              lastDate: DateTime(
                now.year + 2,
              ),
              initialDate: initial,
            );

            if (!mounted) return;

            if (picked != null) {
              final y = picked.year
                  .toString()
                  .padLeft(4, '0');

              final m = picked.month
                  .toString()
                  .padLeft(2, '0');

              final d = picked.day
                  .toString()
                  .padLeft(2, '0');

              widget.onPickDate(
                '$y-$m-$d',
              );
            }
          },
          icon: const Icon(
            Icons.calendar_month,
          ),
          label:
              const Text('pick date'),
        ),
      ],
    );
  }
}