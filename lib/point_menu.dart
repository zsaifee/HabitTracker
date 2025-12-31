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
    // Your "to do’s you’ve been putting off" category
    return c == CategoryType.putOffTodos;
  }

  @override
  Widget build(BuildContext context) {
    // group + sort
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
                'point menu',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Set point values based on what motivates you right now.'),
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
                              '${h.points} pts',
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
                                      title: const Text('Delete habit?'),
                                      content: Text('Delete “${h.name}” everywhere?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Delete'),
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
                    points: 1,
                    category: defaultCat,
                    rank: _nextRankFor(defaultCat),
                    // oneAndDone inferred by Habit ctor; defaultCat => false
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
    final ptsCtrl = TextEditingController(text: habit.points.toString());
    final reasonCtrl = TextEditingController(text: habit.reasoning ?? '');

    bool isExercise = habit.isExercise;

    // local dialog state for category
    CategoryType selectedCat = habit.category;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
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
                      setState(() => selectedCat = c);
                    },
                  ),

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

    // apply edits
    final newName = nameCtrl.text.trim();
    if (newName.isNotEmpty) habit.name = newName;

    final parsedPts = int.tryParse(ptsCtrl.text.trim());
    if (parsedPts != null) habit.points = parsedPts;

    habit.reasoning = reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim();
    habit.isExercise = isExercise;

    // If category changed, update + assign rank inside that category
    if (habit.category != selectedCat) {
      habit.category = selectedCat;
      habit.rank = _nextRankFor(selectedCat, excludeId: habit.id);
    }

    // IMPORTANT: keep oneAndDone in sync with category
    habit.oneAndDone = _isOneAndDoneCategory(habit.category);

    // If rank is placeholder-y, set it to a real next rank
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
