import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../app_style.dart';
import '../storage_service.dart';
import '../category_type.dart';
import '../behavior.dart';
import '../goal.dart';

class SetupWizard extends StatefulWidget {
  final VoidCallback onDone;

  const SetupWizard({super.key, required this.onDone});

  @override
  State<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends State<SetupWizard> {
  final _storage = StorageService();

  int _step = 0;
  bool _busy = false;
  String? _err;

  // in-memory drafts
  final Map<CategoryType, List<_BehaviorDraft>> _byCat = {
    for (final c in CategoryType.values) c: <_BehaviorDraft>[],
  };

  final List<CategoryType> _setupCats = const [
    CategoryType.feelGoodIrregular,
    CategoryType.putOffTodos,
    CategoryType.wantToStart,
    CategoryType.wantToMaintain,
    // keep goals separate if you want later
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('setup'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: AppStyle.headerGradient(context))),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppStyle.pageWash()),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _body(),
        ),
      ),
    );
  }

  Widget _body() {
    if (_busy) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_err != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_err!, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          FilledButton(onPressed: () => setState(() => _err = null), child: const Text('back')),
        ],
      );
    }

    return Column(
      children: [
        Expanded(child: _stepView()),
        const SizedBox(height: 12),
        Row(
        children: [
          if (_step > 0)
            TextButton(
              onPressed: () => setState(() => _step--),
              child: const Text('back'),
            ),

          // ✅ Skip only on ranking step
          if (_step == 3) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: _skipRankingForNow,
              child: const Text('skip for now'),
            ),
          ],

          const Spacer(),

          FilledButton(
            onPressed: _onNext,
            child: Text(_step == 3 ? 'finish' : 'next'),
          ),
        ],
      ),

      ],
    );
  }

  Widget _stepView() {
    switch (_step) {
      case 0:
        return _intro();
      case 1:
        return _categoryInstructions();
      case 2:
        return _brainDump();
      case 3:
        return _rankAndFrequency();
      default:
        return _intro();
    }
  }
Future<void> _skipRankingForNow() async {
  await _onNext();
}

  Widget _intro() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('we’re going to set up your behavior categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          SizedBox(height: 10),
          Text('1) brain dump behaviors into categories\n2) rank them inside each category\n3) choose a gentle frequency target\n\nnothing is permanent — this is just “right now”.'),
        ]),
      ),
    );
  }

  Widget _categoryInstructions() {
    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('how these categories work', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                SizedBox(height: 10),
                Text(
                  'Brain dump first — you’ll filter later in your habit focus view.\n\n'
                  'Try to write behaviors in an “individual behavior lens” (ex: “strength exercise”, not “gym 2x/week”). '
                  'That way you’re not locked to a specific schedule yet — you earn for whatever you actually do.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final c in _setupCats) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(c.setupDescription),
                  const SizedBox(height: 10),
                  const Text('examples', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  ...c.setupExamples.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $e'),
                      )),
                  const SizedBox(height: 10),
                  Text('frequency: ${c.setupFrequencyNote}'),
                  const SizedBox(height: 6),
                  Text('rank: ${c.rankingPrompt}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _brainDump() {
    return ListView(
      children: [
        for (final c in _setupCats) ...[
          _categoryCard(c),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _categoryCard(CategoryType c) {
    final list = _byCat[c]!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'Add behaviors in a “behavior lens” (ex: “strength exercise”, not “gym 2x/week”).',
              style: TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 8),
            if (c.usesFrequency) ...[
              const Text(
                'Frequency (times per week target)',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
            ],
            const SizedBox(height: 10),
            for (final b in list)
              Row(
                children: [
                  Expanded(child: Text(b.name)),

                  if (c.usesFrequency) ...[
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.remove),
                      onPressed: () => setState(() => b.freqPerWeek = (b.freqPerWeek - 1).clamp(0, 21)),
                    ),
                    Text('${b.freqPerWeek}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(() => b.freqPerWeek = (b.freqPerWeek + 1).clamp(0, 21)),
                    ),
                  ],

                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => list.remove(b)),
                  ),
                ],
              ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  final name = await _promptForText(title: 'add behavior', hint: 'ex: strength exercise');
                  if (name == null || name.trim().isEmpty) return;
                  setState(() => list.add(_BehaviorDraft(name.trim())));
                },
                icon: const Icon(Icons.add),
                label: const Text('add'),
              ),
            ),
          ],
        ),
      ),
    );
  }



Widget _rankAndFrequency() {
  return ListView(
    children: [
      for (final c in _setupCats) ...[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Ranking axis:\n${c.rankingPrompt}', style: const TextStyle(color: Colors.black)),
                const SizedBox(height: 10),
                _reorderOnlyList(c),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    ],
  );
}
Widget _reorderOnlyList(CategoryType c) {
  final list = _byCat[c]!;
  if (list.isEmpty) {
    return const Text('No behaviors added here.', style: TextStyle(color: Colors.black));
  }

  return ReorderableListView(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    onReorder: (oldIndex, newIndex) {
      setState(() {
        if (newIndex > oldIndex) newIndex -= 1;
        final item = list.removeAt(oldIndex);
        list.insert(newIndex, item);
      });
    },
    children: [
      for (int i = 0; i < list.length; i++)
        ListTile(
          key: ValueKey('${c.key}-$i-${list[i].name}'),
          leading: const Icon(Icons.drag_handle),
          title: Text('${i + 1}. ${list[i].name}'),
        ),
    ],
  );
}



  Future<void> _onNext() async {
    if (_step < 3) {
      setState(() => _step++);
      return;
    }

    // finish
    setState(() {
      _busy = true;
      _err = null;
    });

    try {
      final behaviors = <Behavior>[];
      final goals = <Goal>[];

      for (final c in _setupCats) {
        final list = _byCat[c]!;
        for (int i = 0; i < list.length; i++) {
          final id = FirebaseFirestore.instance.collection('_').doc().id; // random id
          behaviors.add(
            Behavior(
              id: id,
              name: list[i].name,
              category: c,
              rank: i + 1,
            ),
          );
          goals.add(
            Goal(
              behaviorId: id,
              frequencyPerWeek: c.usesFrequency ? list[i].freqPerWeek : 0,
            ),
          );
        }
      }

      await _storage.saveSetupV2(behaviors: behaviors, goals: goals);

      if (!mounted) return;
      widget.onDone();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _err = 'Setup failed: $e';
      });
      return;
    }
  }

  Future<String?> _promptForText({required String title, required String hint}) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(hintText: hint),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('add')),
        ],
      ),
    );
  }
}

class _BehaviorDraft {
  String name;
  int freqPerWeek;

  _BehaviorDraft(this.name) : freqPerWeek = 3;
}
