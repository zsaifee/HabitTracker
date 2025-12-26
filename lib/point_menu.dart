import 'package:flutter/material.dart';
import 'app_style.dart';
import 'habit.dart';



class PointMenuPage extends StatelessWidget {
  final List<Habit> habits;
  final VoidCallback onChanged;
  final Future<void> Function(String habitId) onDeleteHabit;

  const PointMenuPage({super.key, 
    required this.habits,
    required this.onChanged,
    required this.onDeleteHabit,
  });

  @override
  Widget build(BuildContext context) {
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
              child: Text('Set point values for habits + exercise based on what motivates you right now.'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
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
                                habits.removeWhere((x) => x.id == h.id); 
                                onChanged(); 
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