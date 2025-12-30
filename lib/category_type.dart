// ==============================
// category_type.dart
// ==============================

enum CategoryType {
  feelGoodIrregular,
  putOffTodos,
  wantToStart,
  wantToMaintain,
}

extension CategoryTypeX on CategoryType {
  static CategoryType fromKey(String key) {
    return CategoryType.values.firstWhere(
      (c) => c.key == key,
      orElse: () => CategoryType.wantToMaintain,
    );
  }

  String get key => switch (this) {
        CategoryType.feelGoodIrregular => 'feel_good_irregular',
        CategoryType.putOffTodos => 'put_off_todos',
        CategoryType.wantToStart => 'want_to_start',
        CategoryType.wantToMaintain => 'want_to_maintain',
      };

  String get title => switch (this) {
        CategoryType.feelGoodIrregular => 'feel-good, irregular behaviors',
        CategoryType.putOffTodos => 'to do’s you’ve been putting off',
        CategoryType.wantToStart => 'habits you want to start',
        CategoryType.wantToMaintain => 'habits you want to maintain',
      };

  String get rankingPrompt => switch (this) {
        CategoryType.feelGoodIrregular =>
          'Most difficult to convince yourself to do / least frequent → least difficult / most frequent',
        CategoryType.wantToMaintain =>
          'Least solid / hardest to keep → most solid / easiest to keep',
        CategoryType.wantToStart =>
          'Most difficult to start → least difficult to start',
        CategoryType.putOffTodos =>
          'Most painful / longest procrastinated → least painful / least procrastinated',
      };

  // -----------------------------
  // Setup copy + behavior guidance
  // -----------------------------
  bool get usesFrequency => switch (this) {
        CategoryType.wantToStart => true,
        CategoryType.wantToMaintain => true,
        _ => false,
      };

  String get setupDescription => switch (this) {
        CategoryType.feelGoodIrregular =>
          'High-effort or emotionally loaded actions you don’t do often, but that noticeably improve your life when you do them. These are less “habits” and more intentional resets/check-ins.',
        CategoryType.putOffTodos =>
          'Tasks that create mental drag just by existing. Often small, but avoided due to dread, ambiguity, or emotional friction. One-time — you’ll do them once and move on.',
        CategoryType.wantToStart =>
          'New behaviors you’re intentionally building that aren’t automatic yet. These need gentle reinforcement and a realistic target.',
        CategoryType.wantToMaintain =>
          'Established routines you already do fairly consistently, but still want to acknowledge and protect from burnout or decay.',

      };

  List<String> get setupExamples => switch (this) {
        CategoryType.feelGoodIrregular => const [
            'budget review / money check-in',
            'deep clean',
            'closet purge',
            'update resume / portfolio',
            'therapy reflection / journaling dump',
            'plan a trip',
          ],
        CategoryType.putOffTodos => const [
            'schedule a doctor/dentist appointment',
            'respond to a difficult email/text',
            'cancel a subscription',
            'mail something',
            'make returns',
          ],
        CategoryType.wantToStart => const [
            'morning stretch',
            'read before bed',
            'drink enough water',
            'daily walk',
            'meditation practice',
          ],
        CategoryType.wantToMaintain => const [
            'take meds',
            'brush/floss',
            'go to class/work',
            'exercise you already do',
            'sleep routine',
          ],
      };

  String get setupFrequencyNote => switch (this) {
        CategoryType.wantToStart => 'Configurable (choose a gentle times/week target).',
        CategoryType.wantToMaintain => 'Fixed, recurring (usually daily or weekly).',
        _ => 'Not needed for this category.',
      };
}
