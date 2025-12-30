import 'package:flutter/material.dart';
import 'app_style.dart';
import 'fund_type.dart';

class FundsPage extends StatelessWidget {
  final double Function(FundType) fundValue;
  final Future<void> Function(FundType, double delta) onAdjust;

  const FundsPage({
    super.key,
    required this.fundValue,
    required this.onAdjust,
  });

  // Defaults (you can later load these from Firestore/settings)
  static const double _lilTreatDefault = 6.00;

  static const List<_PurchaseOption> _funPurchaseOptions = [
    _PurchaseOption('movie ticket', 18),
    _PurchaseOption('book', 15),
    _PurchaseOption('cute top', 32),
  ];

  @override
  Widget build(BuildContext context) {
    Widget card(FundType t, String description) {
      final v = fundValue(t);
      final c = AppStyle.fundColor(t);

      return Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header
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

                  // actions
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

                  // preset cash out buttons (only for lilTreat + funPurchase)
                  if (t == FundType.lilTreat || t == FundType.funPurchase) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Quick cash out',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _presetRow(context, t),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(gradient: AppStyle.pageWash()),
      child: ListView(
        padding: const EdgeInsets.all(16),
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
          card(
            FundType.saver,
            'big life stuff: trips, house, wedding, “i’ll be rich eventually” energy.',
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text('Tip: funds are saved in your browser (localStorage) automatically.'),
          ),
        ],
      ),
    );
  }

  Widget _presetRow(BuildContext context, FundType t) {
    final balance = fundValue(t);

    if (t == FundType.lilTreat) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: balance <= 0
                ? null
                : () => _cashOutSheet(
                      context,
                      t,
                      preset: _CashOutPreset(label: 'lil treat', amount: _lilTreatDefault),
                    ),
            icon: const Icon(Icons.local_cafe_outlined),
            label: const Text('latte (~\$6)'),
          ),
          TextButton(
            onPressed: balance <= 0 ? null : () => _cashOutSheet(context, t, preset: null),
            child: const Text('custom'),
          ),
        ],
      );
    }

    // funPurchase
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._funPurchaseOptions.map((opt) {
          return OutlinedButton(
            onPressed: balance <= 0
                ? null
                : () => _cashOutSheet(
                      context,
                      t,
                      preset: _CashOutPreset(label: opt.label, amount: opt.amount),
                    ),
            child: Text('${opt.label} (\$${opt.amount.toStringAsFixed(0)})'),
          );
        }),
        TextButton(
          onPressed: balance <= 0 ? null : () => _cashOutSheet(context, t, preset: null),
          child: const Text('custom'),
        ),
      ],
    );
  }

  

  Future<void> _cashOutSheet(
    BuildContext context,
    FundType t, {
    required _CashOutPreset? preset,
  }) async {
    final balance = fundValue(t);
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
          builder: (ctx, setState) {
            final current = double.tryParse(ctrl.text) ?? 0.0;

            void setAmount(double v) {
              ctrl.text = clamp(v).toStringAsFixed(2);
              setState(() => err = null);
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
                      style: TextStyle(color: Colors.black)),
                  const SizedBox(height: 14),

                  TextField(
                    controller: ctrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'amount',
                      prefixText: '\$',
                      errorText: err,
                    ),
                    onChanged: (_) => setState(() => err = null),
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
                                    setState(() => err = 'Enter a valid number.');
                                    return;
                                  }
                                  final amt = clamp(raw);
                                  if (amt <= 0) {
                                    setState(() => err = 'Amount must be > 0.');
                                    return;
                                  }
                                  if (amt > balance) {
                                    setState(() => err = 'Not enough balance.');
                                    return;
                                  }

                                  Navigator.pop(ctx);
                                  await onAdjust(t, -amt);
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

class _PurchaseOption {
  final String label;
  final double amount;
  const _PurchaseOption(this.label, this.amount);
}

class _CashOutPreset {
  final String label;
  final double amount;
  const _CashOutPreset({required this.label, required this.amount});
}
