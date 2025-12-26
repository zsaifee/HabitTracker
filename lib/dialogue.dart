import 'package:flutter/material.dart';

Future<void> _showHabitBankDialog({
  required BuildContext context,
  required String title,
  required Widget content,
  String primaryText = "continue",
  VoidCallback? onPrimary,
  String? secondaryText,
  VoidCallback? onSecondary,
  bool barrierDismissible = false,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: content,
        actions: [
          if (secondaryText != null)
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (onSecondary != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    onSecondary();
                  });
                }
              },
              child: Text(secondaryText),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (onPrimary != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onPrimary();
                });
              }
            },
            child: Text(primaryText),
          ),
        ],
      );
    },
  );
}

// Walkthrough dialogs

void showWelcomeDialog(BuildContext context) {
  _showHabitBankDialog(
    context: context,
    title: "welcome to the habit bank! 🏦",
    content: const Text(
    "turn your good habits into treats you actually want.\n\n"
    "here's the thing: you were probably going to \n\n"
    "buy yourself that coffee or those shoes anyway.\n\n"
    "now you get to feel like you earned it.\n",
    ),
    primaryText: "get started",
    onPrimary: () => showConceptDialog(context),
  );
}

void showConceptDialog(BuildContext context) {
  _showHabitBankDialog(
    context: context,
    title: "here’s how it works:",
    content: const Text(

      "every habit you complete earns you money toward real treats./n/n"
      "but here's the key—not all habits earn the same way...\n\n"
      "some habits feel like taking care of yourself today.\n"
      "others feel like building who you want to become."
      "they deserve different kinds of rewards."
    ),
    onPrimary: () => showLilTreatDialog(context),
  );
}

void showLilTreatDialog(BuildContext context) {
  _showHabitBankDialog(
    context: context,
    title: "☕ lil treat fund",
    content: const Text(
      "this is for habits that feel like self-care:\n"
      "gentle walks, cooking at home, skincare, making your bed, stretching.\n\n"
      "earn toward treats that make your day better:\n"
      "• coffee out or a bagel\n"
      "• a croissant or matcha\n"
      "• a fun new snack\n\n"
      "use it on errands, commutes, long walks, or catching up with a friend.\n"
      "why? because you deserve it. nice job :)",
    ),
    onPrimary: () => showFunPurchaseDialog(context),
  );
}

void showFunPurchaseDialog(BuildContext context) {
  _showHabitBankDialog(
    context: context,
    title: "✨ fun purchase fund",
    content: const Text(
""
    ),
    onPrimary: () => showGoalDialog(context),
  );
}

// TEMP placeholder so your file compiles.
// Replace this with your real “Screen 5: Set Your Goals” dialog next.
void showGoalDialog(BuildContext context) {
  _showHabitBankDialog(
    context: context,
    title: "what are you saving for?",
    content: const Text(
      "add fun purchases to your wish list along with estimated costs.\n\n"
      "you can always change these later.",
    ),
    secondaryText: "skip for now",
    onSecondary: () {
      // next step later (first habit dialog)
    },
    primaryText: "continue",
    onPrimary: () => showGoalDialog(context),    
      
  );
}

// -------------------------
// Help dialog (from ? icon)
// -------------------------

Future<void> helpDialog(BuildContext context) {
  return _showHabitBankDialog(
    context: context,
    title: "how the habit bank works",
    content: const Text(
      "complete habits → earn dollars toward treats.\n\n"
      "☕ lil treat fund: small joys you can use soon.\n"
      "✨ fun purchase fund: bigger wish-list splurges.\n\n"
      "want to see the full walkthrough?",
    ),
    secondaryText: "close",
    onSecondary: () {},
    primaryText: "open walkthrough",
    onPrimary: () => showWelcomeDialog(context),
    barrierDismissible: true, // let them tap outside to exit help
  );
}
