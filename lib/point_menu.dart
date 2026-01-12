// ==============================
// point_menu.dart
// ==============================

import 'package:flutter/material.dart';
import 'app_style.dart';
import 'habit.dart';
import 'category_type.dart';

class PointMenuPage extends StatelessWidget {
  final List<Habit> habits;
  final Future<void> Function() onChanged;
  final Future<void> Function(String habitId) onDeleteHabit;

  const PointMenuPage({
    super.key,
    required this.habits,
    required this.onChanged,
    required this.onDeleteHabit,
  });

  int _nextRankFor(CategoryType cat, {String? excludeId}) {
    final maxRank = habits
        .where((h) => h.category == cat && (excludeId == null || h.id != excludeId))
        .fold<int>(0, (m, h) => h.rank > m ? h.rank : m);
    return maxRank + 1;
  }

  bool _isOneAndDoneCategory(CategoryType c) {
    return c == CategoryType.putOffTodos;
  }

  int _defaultDollars(CategoryType c) => Habit.defaultPointsForCategory(c);
  int _clampDollars(int v) => Habit.clampPoints(v);

  @override
  Widget build(BuildContext context) {
    final grouped = <CategoryType, List<Habit>>{
      for (final c in CategoryType.values) c: <Habit>[],
    };

    for (final h in habits) {
      grouped[h.category]!.add(h);
    }

    for (final c in grouped.keys) {
      grouped[c]!.sort((a, b) => a.rank.compareTo(b.rank));
    }

    final catsInUse = grouped.entries.where((e) => e.value.isNotEmpty).toList();

    return Container(
      decoration: BoxDecoration(gradient: AppStyle.pageWash()),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'menu',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('set dollar values based on what motivates you right now.'),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: Card(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    for (final entry in catsInUse) ...[
                      _CategoryHeader(title: entry.key.title),
                      for (final h in entry.value) ...[
                        ListTile(
                          title: Text(h.name),
                          subtitle: Text(
                            [
                              '\$${h.points}',
                              if (h.isExercise) 'exercise',
                              if ((h.reasoning ?? '').trim().isNotEmpty) '“${h.reasoning}”',
                              if (h.oneAndDone) 'one-and-done',
                            ].join(' • '),
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                tooltip: 'edit',
                                onPressed: () async {
                                  await _editHabitDialog(context, h);
                                  await onChanged();
                                },
                                icon: const Icon(Icons.edit),
                              ),
                              IconButton(
                                tooltip: 'delete',
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('delete habit?'),
                                      content: Text('delete “${h.name}” everywhere?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('delete'),
                                        ),
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
                        ),
                        const Divider(height: 1),
                      ],
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final defaultCat = CategoryType.wantToMaintain;

                  final newHabit = Habit(
                    id: 'h_${DateTime.now().microsecondsSinceEpoch}',
                    name: 'new habit',
                    points: _defaultDollars(defaultCat),
                    category: defaultCat,
                    rank: _nextRankFor(defaultCat),
                  );

                  habits.add(newHabit);
                  await _editHabitDialog(context, newHabit);
                  await onChanged();
                },
                icon: const Icon(Icons.add),
                label: const Text('add habit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editHabitDialog(BuildContext context, Habit habit) async {
    final nameCtrl = TextEditingController(text: habit.name);
    final reasonCtrl = TextEditingController(text: habit.reasoning ?? '');

    bool isExercise = habit.isExercise;
    CategoryType selectedCat = habit.category;

    int dollars = _clampDollars(habit.points);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('edit habit'),
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
                    onChanged: (v) => setState(() => dollars = v.round()),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'default for this category is \$${_defaultDollars(selectedCat)} '
                      '(you can customize \$1–\$10).',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),

                  const SizedBox(height: 20),

                  DropdownButtonFormField<CategoryType>(
                    initialValue: selectedCat,
                    decoration: const InputDecoration(labelText: 'category'),
                    items: [
                      for (final c in CategoryType.values)
                        DropdownMenuItem(
                          value: c,
                          child: Text(c.title),
                        ),
                    ],
                    onChanged: (c) {
                      if (c == null) return;

                      final oldCat = selectedCat;
                      final oldDefault = _defaultDollars(oldCat);
                      final newDefault = _defaultDollars(c);

                      setState(() {
                        selectedCat = c;
                        if (dollars == oldDefault) {
                          dollars = newDefault;
                        }
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: reasonCtrl,
                    decoration: const InputDecoration(labelText: 'reasoning (optional)'),
                  ),
                  const SizedBox(height: 8),

                  SwitchListTile(
                    value: isExercise,
                    onChanged: (v) => setState(() => isExercise = v),
                    title: const Text('mark as exercise'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('done'),
              ),
            ],
          ),
        );
      },
    );

    final newName = nameCtrl.text.trim();
    if (newName.isNotEmpty) habit.name = newName;

    habit.points = _clampDollars(dollars);
    habit.reasoning = reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim();
    habit.isExercise = isExercise;

    if (habit.category != selectedCat) {
      habit.category = selectedCat;
      habit.rank = _nextRankFor(selectedCat, excludeId: habit.id);
    }

    habit.oneAndDone = _isOneAndDoneCategory(habit.category);

    if (habit.rank <= 0 || habit.rank >= 9999) {
      habit.rank = _nextRankFor(habit.category, excludeId: habit.id);
    }
  }
}

class _CategoryHeader extends StatelessWidget {
  final String title;
  const _CategoryHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
      ),
    );
  }
}
