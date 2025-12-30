import 'package:flutter/material.dart';
import 'app_style.dart';

class SignupOnboarding extends StatefulWidget {
  final VoidCallback onDone;
  const SignupOnboarding({super.key, required this.onDone});

  @override
  State<SignupOnboarding> createState() => _SignupOnboardingState();
}

class _SignupOnboardingState extends State<SignupOnboarding> {
  final _pc = PageController();
  int _i = 0;

  static const _pages = <_P>[
    _P(
      title: 'welcome to the habit bank 🏦',
      body:
          "let's be real.\n\n"
          "you're getting that matcha from the cafe\n"
          "down the street anyway.\n\n"
          "you're buying those sneakers when yours\n"
          "get scuffed anyway.\n\n"
          "you work for your money. but you're working\n"
          "and spending regardless.\n\n"
          "so why not connect them?\n\n"
          "do the hard things. earn the treats.\n"
          "feel good about both.",
      cta: 'continue',
    ),
    _P(
      title: "here's how it works:",
      body:
          "complete a habit → earn money toward a fund\n\n"
          "there are two funds, and you decide which\n"
          "habits earn toward which one.",
      cta: 'continue',
    ),
    _P(
      title: "☕ lil treat fund",
      body:
          "for treats you can enjoy soon.\n\n"
          "coffee or matcha. lunch out. a bagel.\n"
          "face mask. fresh flowers. the croissant\n"
          "from that bakery.\n\n"
          "small joys that make your day better.",
      cta: 'continue',
    ),
    _P(
      title: "✨ fun purchase fund",
      body:
          "for bigger things you've been wanting.\n\n"
          "new shoes. a bag. skincare haul.\n"
          "room decor. books. that jacket.\n"
          "the nice dinner out.\n\n"
          "things you screenshot but don't buy... yet.",
      cta: 'continue',
    ),
    _P(
      title: "here's how people use it",
      body:
          "everyone's different. some examples:\n\n"
          "maya values \"wake up at first alarm\" at \$5\n"
          "toward lil treat fund - it's really hard for\n"
          "her and she wants that coffee.\n\n"
          "james values \"morning yoga\" at \$2 toward\n"
          "fun purchase fund - he does it regularly,\n"
          "it's just maintenance.\n\n"
          "the same habit can mean different things\n"
          "to different people. that's the point.",
      cta: 'continue',
    ),
    _P(
      title: "you're in control",
      body:
          "your relationship with habits changes.\n\n"
          "something might be hard today and easy\n"
          "in a month. or vice versa.\n\n"
          "you can adjust values and switch funds\n"
          "anytime - there's no \"right\" way to do this.\n\n"
          "just what feels honest to you right now.",
      cta: "let's get started",
      isFinal: true,
    ),
  ];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    final last = _i == _pages.length - 1;
    if (!last) {
      _pc.nextPage(duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: AppStyle.headerGradient(context))),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppStyle.pageWash()),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  itemCount: _pages.length,
                  onPageChanged: (v) => setState(() => _i = v),
                  itemBuilder: (_, idx) {
                    final p = _pages[idx];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 14),
                            Text(p.body, style: const TextStyle(fontSize: 16, height: 1.25)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_i > 0)
                    TextButton(
                      onPressed: () => _pc.previousPage(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      ),
                      child: const Text('back'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    child: Text(_pages[_i].cta),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _P {
  final String title;
  final String body;
  final String cta;
  final bool isFinal;
  const _P({required this.title, required this.body, required this.cta, this.isFinal = false});
}
