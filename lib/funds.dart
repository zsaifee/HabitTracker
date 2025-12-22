import 'package:flutter/material.dart';
import 'app_style.dart';
import 'fund_type.dart';


class FundsPage extends StatelessWidget {
  final double Function(FundType) fundValue;
  final Future<void> Function(FundType, double delta) onAdjust;

  const FundsPage({
    required this.fundValue,
    required this.onAdjust,
  });


  @override
  Widget build(BuildContext context) {
    Widget card(FundType t, String description) {
      final v = fundValue(t);
      final c = AppStyle.fundColor(t);

      return Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // colored header strip
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
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
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _spendDialog(context, t),
                        icon: const Icon(Icons.remove),
                        label: const Text('spend'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: c,
                          foregroundColor: Colors.black87,
                        ),
                        onPressed: () => _addDialog(context, t),
                        icon: const Icon(Icons.add),
                        label: const Text('add'),
                      ),
                    ],
                  ),
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
