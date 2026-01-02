import 'package:flutter/material.dart';
import 'app_style.dart';
import 'fund_type.dart';
import 'storage_service.dart';

class FundsPage extends StatefulWidget {
  final double Function(FundType) fundValue;
  final Future<void> Function(FundType, double delta) onAdjust;

  const FundsPage({
    super.key,
    required this.fundValue,
    required this.onAdjust,
  });

  @override
  State<FundsPage> createState() => _FundsPageState();
}

class _FundsPageState extends State<FundsPage> {
  static const double _lilTreatDefault = 6.00;

  final _storage = StorageService();

  bool _goalsLoading = true;
  List<_FunGoal> _goals = <_FunGoal>[];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final raw = await _storage.loadFunPurchaseGoalsRaw();
      final goals = raw.map(_FunGoal.fromMap).toList()
        ..sort((a, b) => a.createdAtMs.compareTo(b.createdAtMs));
      if (!mounted) return;
      setState(() {
        _goals = goals;
        _goalsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _goalsLoading = false);
    }
  }

  Future<void> _persistGoals() async {
    await _storage.saveFunPurchaseGoalsRaw(_goals.map((g) => g.toMap()).toList());
  }

  Future<void> _addGoal(String name, double price) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final g = _FunGoal(
      id: id,
      name: name,
      price: price,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );

    setState(() => _goals = [..._goals, g]);
    await _persistGoals();
  }

  Future<void> _deleteGoal(String id) async {
    setState(() => _goals = _goals.where((g) => g.id != id).toList());
    await _persistGoals();
  }

  Future<void> _cashOutGoal(_FunGoal goal) async {
    final bal = widget.fundValue(FundType.funPurchase);
    if (goal.price <= 0) return;
    if (bal < goal.price) return;

    await widget.onAdjust(FundType.funPurchase, -goal.price);

    // remove goal after cash out
    await _deleteGoal(goal.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cashed out \$${goal.price.toStringAsFixed(2)} for "${goal.name}"')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final funBalance = widget.fundValue(FundType.funPurchase);

    Widget card(FundType t, String description) {
      final v = widget.fundValue(t);
      final c = AppStyle.fundColor(t);

      return Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(t.icon, color: Colors.black87),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t.label,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (t == FundType.funPurchase)
                    TextButton.icon(
                      onPressed: _addGoalSheet,
                      icon: const Icon(Icons.add),
                      label: const Text('add goal'),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(description),
                  const SizedBox(height: 12),
                  Text(
                    '\$${v.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: v <= 0 ? null : () => _cashOutSheet(context, t, preset: null),
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text('cash out'),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // NOTE: maxHeight is used so the panel can scroll instead of overflow on desktop
    Widget goalsPanel(double maxHeight) {
      if (_goalsLoading) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        );
      }

      return SizedBox(
        height: maxHeight,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // header stays fixed
                Row(
                  children: [
                    const Text(
                      'Fun purchase goals',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addGoalSheet,
                      icon: const Icon(Icons.add),
                      label: const Text('add'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Saved: \$${funBalance.toStringAsFixed(2)}'),
                const SizedBox(height: 12),

                // list scrolls
                Expanded(
                  child: _goals.isEmpty
                      ? const Align(
                          alignment: Alignment.topLeft,
                          child: Text('No goals yet — add one to track progress.'),
                        )
                      : ListView.builder(
                          itemCount: _goals.length,
                          itemBuilder: (context, i) {
                            final g = _goals[i];
                            final progress = (g.price <= 0)
                                ? 0.0
                                : (funBalance / g.price).clamp(0.0, 1.0);
                            final remaining = g.price - funBalance;
                            final reached = remaining <= 0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _goalTile(
                                goal: g,
                                progress: progress,
                                remaining: remaining,
                                reached: reached,
                                onDelete: () => _deleteGoal(g.id),
                                onCashOut: () => _cashOutGoal(g),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(gradient: AppStyle.pageWash()),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;

          if (!isWide) {
            // mobile: everything scrolls naturally
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // on mobile, don't force a max height—let it size naturally
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Fun purchase goals',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _addGoalSheet,
                              icon: const Icon(Icons.add),
                              label: const Text('add'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Saved: \$${funBalance.toStringAsFixed(2)}'),
                        const SizedBox(height: 12),
                        if (_goalsLoading)
                          const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
                        else if (_goals.isEmpty)
                          const Text('No goals yet — add one to track progress.')
                        else
                          Column(
                            children: _goals.map((g) {
                              final progress = (g.price <= 0)
                                  ? 0.0
                                  : (funBalance / g.price).clamp(0.0, 1.0);
                              final remaining = g.price - funBalance;
                              final reached = remaining <= 0;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _goalTile(
                                  goal: g,
                                  progress: progress,
                                  remaining: remaining,
                                  reached: reached,
                                  onDelete: () => _deleteGoal(g.id),
                                  onCashOut: () => _cashOutGoal(g),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                card(
                  FundType.lilTreat,
                  'coffee, croissants, lil snacks, movie solo — spend pretty quickly.',
                ),
                const SizedBox(height: 12),
                card(
                  FundType.funPurchase,
                  'save up for a fun want (new shoes, skincare, class, etc).',
                ),
              ],
            );
          }

          // desktop/tablet: left scroll + right fixed-height scroll panel
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      card(
                        FundType.lilTreat,
                        'coffee, croissants, lil snacks, movie solo — spend pretty quickly.',
                      ),
                      const SizedBox(height: 12),
                      card(
                        FundType.funPurchase,
                        'save up for a fun want (new shoes, skincare, class, etc).',
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 360,
                  child: goalsPanel(constraints.maxHeight),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _goalTile({
    required _FunGoal goal,
    required double progress,
    required double remaining,
    required bool reached,
    required VoidCallback onDelete,
    required VoidCallback onCashOut,
  }) {
    final remainingText = reached ? 'Goal reached 🎉' : '\$${remaining.toStringAsFixed(2)} to go';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name.trim().isEmpty ? 'Goal item' : goal.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Delete goal',
                onPressed: onDelete,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text('Goal: \$${goal.price.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('${(progress * 100).round()}%'),
              const Spacer(),
              Text(
                remainingText,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: reached ? Colors.green.shade700 : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: reached ? onCashOut : null,
              icon: const Icon(Icons.payments),
              label: Text(
              reached
                  ? 'cash out ${goal.name.trim().isEmpty ? 'goal' : goal.name}'
                  : 'reach goal to cash out',
            ),

            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addGoalSheet() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String? err;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add fun purchase goal',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'item',
                      hintText: 'e.g., skincare, shoes, class',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'price',
                      prefixText: '\$',
                      errorText: err,
                    ),
                    onChanged: (_) => setSheetState(() => err = null),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          nameCtrl.text = '';
                          priceCtrl.text = '';
                          setSheetState(() => err = null);
                        },
                        child: const Text('clear'),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () async {
                          final raw = double.tryParse(priceCtrl.text.trim());
                          if (raw == null) {
                            setSheetState(() => err = 'Enter a valid price.');
                            return;
                          }
                          if (raw <= 0) {
                            setSheetState(() => err = 'Price must be > 0.');
                            return;
                          }

                          final name = nameCtrl.text.trim();
                          Navigator.pop(ctx);
                          await _addGoal(name, raw);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('add goal'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _cashOutSheet(
    BuildContext context,
    FundType t, {
    required _CashOutPreset? preset,
  }) async {
    final balance = widget.fundValue(t);
    final presetAmount = preset?.amount ?? (balance >= _lilTreatDefault ? _lilTreatDefault : balance);

    final ctrl = TextEditingController(text: presetAmount.toStringAsFixed(2));
    String? err;

    double clamp(double v) => v.clamp(0.0, balance);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateSheet) {
            final current = double.tryParse(ctrl.text) ?? 0.0;

            void setAmount(double v) {
              ctrl.text = clamp(v).toStringAsFixed(2);
              setStateSheet(() => err = null);
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset == null ? 'Cash out • ${t.label}' : 'Cash out • ${t.label} • ${preset.label}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text('Balance: \$${balance.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.black)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: ctrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'amount',
                      prefixText: '\$',
                      errorText: err,
                    ),
                    onChanged: (_) => setStateSheet(() => err = null),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(onPressed: () => setAmount(current - 1), child: const Text('-1')),
                      OutlinedButton(onPressed: () => setAmount(current - 5), child: const Text('-5')),
                      OutlinedButton(onPressed: () => setAmount(current + 1), child: const Text('+1')),
                      OutlinedButton(onPressed: () => setAmount(current + 5), child: const Text('+5')),
                      TextButton(onPressed: () => setAmount(balance), child: const Text('max')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: balance <= 0
                              ? null
                              : () async {
                                  final raw = double.tryParse(ctrl.text.trim());
                                  if (raw == null) {
                                    setStateSheet(() => err = 'Enter a valid number.');
                                    return;
                                  }
                                  final amt = clamp(raw);
                                  if (amt <= 0) {
                                    setStateSheet(() => err = 'Amount must be > 0.');
                                    return;
                                  }
                                  if (amt > balance) {
                                    setStateSheet(() => err = 'Not enough balance.');
                                    return;
                                  }

                                  Navigator.pop(ctx);
                                  await widget.onAdjust(t, -amt);
                                },
                          icon: const Icon(Icons.payments),
                          label: Text('cash out \$${clamp(current).toStringAsFixed(2)}'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _FunGoal {
  final String id;
  final String name;
  final double price;
  final int createdAtMs;

  const _FunGoal({
    required this.id,
    required this.name,
    required this.price,
    required this.createdAtMs,
  });

  factory _FunGoal.fromMap(Map<String, dynamic> m) {
    final id = (m['id'] as String?) ?? '';
    final name = (m['name'] as String?) ?? '';
    final priceRaw = m['price'];
    final createdRaw = m['createdAtMs'];

    final price = priceRaw is num ? priceRaw.toDouble() : 0.0;
    final createdAtMs = createdRaw is num ? createdRaw.toInt() : 0;

    return _FunGoal(
      id: id,
      name: name,
      price: price,
      createdAtMs: createdAtMs,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'price': price,
        'createdAtMs': createdAtMs,
      };
}

class _CashOutPreset {
  final String label;
  final double amount;
  const _CashOutPreset({required this.label, required this.amount});
}
