// ==============================
// category_type.dart
// ==============================

enum CategoryType {
  feelGoodIrregular,
  putOffTodos,
  wantToStart,
  wantToMaintain,
  goalsAndAccomplishments,
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
        CategoryType.goalsAndAccomplishments => 'goals_and_accomplishments',
      };

  String get title => switch (this) {
        CategoryType.feelGoodIrregular => 'feel-good, irregular behaviors',
        CategoryType.putOffTodos => 'to do’s you’ve been putting off',
        CategoryType.wantToStart => 'habits you want to start',
        CategoryType.wantToMaintain => 'habits you want to maintain',
        CategoryType.goalsAndAccomplishments => 'goals & accomplishments',
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
        CategoryType.goalsAndAccomplishments =>
          'Optional milestones (not repeatable habits)',
      };
}
