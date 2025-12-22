import 'package:flutter/material.dart';

import 'app_style.dart';
import 'habit.dart';
import 'fund_type.dart';
import 'day_log.dart';

class DailyPage extends StatefulWidget {
  final List<Habit> habits;
  final String dateKey;
  final void Function(String newDateKey) onPickDate;

  final DayLog log;
  final int earnedPoints;

  final Future<void> Function(String habitId, bool checked) onToggleHabit;
  final Future<void> Function(String note) onNoteChanged;
  final Future<void> Function(FundType fund, double amount) onDeposit;

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
  });

  @override
  State<DailyPage> createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> {
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.log.note);

    _noteCtrl.addListener(() {
      widget.onNoteChanged(_noteCtrl.text);
    });
  }

  @override
  void didUpdateWidget(covariant DailyPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.dateKey != widget.dateKey) {
      final newText = widget.log.note;
      if (_noteCtrl.text != newText) {
        _noteCtrl.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final earnedDollars = widget.earnedPoints.toDouble();

    return Container(
      decoration: BoxDecoration(gradient: AppStyle.pageWash()),
      child: Padding(
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
                      Expanded(child: SingleChildScrollView(child: left)),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 420,
                        child: SingleChildScrollView(child: right),
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
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'today',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 26),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFD7CFFF)),
                  ),
                  child: Text(
                    'earned \$${earnedDollars.toStringAsFixed(0)} ✨',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text('daily note'),
            const SizedBox(height: 8),
            TextField(
              controller: _noteCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'a few words… or a full rant…',
              ),
            ),
            const SizedBox(height: 16),
            const Text('habits completed'),
            const SizedBox(height: 8),
            ...widget.habits.map((h) {
              final checked =
                  widget.log.completedHabitIds.contains(h.id);
              return CheckboxListTile(
                value: checked,
                onChanged: (v) =>
                    widget.onToggleHabit(h.id, v ?? false),
                title: Text(h.isExercise ? '🏃 ${h.name}' : h.name),
                subtitle: Text(
                  '${h.points} pts${h.isExercise ? ' • exercise' : ''}',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _dailyRight(BuildContext context) {
    final earnedDollars = widget.earnedPoints.toDouble();

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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
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
              style: TextStyle(fontWeight: FontWeight.w700),
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

  Widget _fundDepositButton(
    BuildContext context,
    FundType fund,
    double amount,
  ) {
    final fundColor = AppStyle.fundColor(fund);

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: fundColor,
          foregroundColor: Colors.black87,
        ),
        onPressed: amount <= 0
            ? null
            : () async {
                // ✅ OPTION A: capture BEFORE await
                final messenger = ScaffoldMessenger.of(context);

                await widget.onDeposit(fund, amount);
                if (!mounted) return;

                messenger.showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.black87,
                    content: Text(
                      'deposited \$${amount.toStringAsFixed(0)} '
                      'into ${fund.label} ✨',
                    ),
                  ),
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
          widget.dateKey,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: () async {
            final now = DateTime.now();
            final initial =
                DateTime.tryParse(widget.dateKey) ?? now;

            final picked = await showDatePicker(
              context: context,
              firstDate: DateTime(now.year - 2),
              lastDate: DateTime(now.year + 2),
              initialDate: initial,
            );

            if (!mounted) return;

            if (picked != null) {
              final y = picked.year.toString().padLeft(4, '0');
              final m = picked.month.toString().padLeft(2, '0');
              final d = picked.day.toString().padLeft(2, '0');
              widget.onPickDate('$y-$m-$d');
            }
          },
          icon: const Icon(Icons.calendar_month),
          label: const Text('pick date'),
        ),
      ],
    );
  }
}
