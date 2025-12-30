import 'package:flutter/material.dart';

import 'setup_wizard.dart';
import 'signup_onboarding.dart'; // the pager screens 1-6 from earlier
import 'home_shell.dart';        // your main app shell (tabs)

class FirstRunFlow extends StatefulWidget {
  const FirstRunFlow({super.key});

  @override
  State<FirstRunFlow> createState() => _FirstRunFlowState();
}

class _FirstRunFlowState extends State<FirstRunFlow> {
  int _phase = 0; // 0 = setup wizard, 1 = onboarding story, 2 = app

  void _goToOnboarding() => setState(() => _phase = 1);
  void _finish() => setState(() => _phase = 2);

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case 0:
        return SetupWizard(onDone: _goToOnboarding);

      case 1:
        return SignupOnboarding(onDone: _finish);

      default:
        return const HabitHome();
    }
  }
}
