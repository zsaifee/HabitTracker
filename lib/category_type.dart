// ==============================
// category_type.dart
// ==============================

enum CategoryType {
  daily,
  weekly,
  monthly,
}

extension CategoryTypeX on CategoryType {
  static CategoryType fromKey(String key) {
    return CategoryType.values.firstWhere(
      (c) => c.key == key,
      orElse: () => CategoryType.daily,
    );
  }

  String get key => switch (this) {
        CategoryType.daily => 'daily',
        CategoryType.weekly => 'weekly',
        CategoryType.monthly => 'monthly',
      };

  String get title => switch (this) {
        CategoryType.daily => 'daily',
        CategoryType.weekly => 'weekly',
        CategoryType.monthly => 'monthly',
      };

  String get rankingPrompt => switch (this) {
        CategoryType.daily => 'Daily habits',
        CategoryType.weekly => 'Weekly habits',
        CategoryType.monthly => 'Monthly habits',
      };

  bool get usesFrequency => true;

  String get setupDescription => switch (this) {
        CategoryType.daily =>
          'Small recurring habits you want to do every day.',
        CategoryType.weekly =>
          'Recurring habits you want to do about once a week.',
        CategoryType.monthly =>
          'Recurring habits you only need to do once in a while.',
      };

  List<String> get setupExamples => switch (this) {
        CategoryType.daily => const [
            'take meds',
            'drink water',
            'stretch',
            'read',
            'journal',
          ],

        CategoryType.weekly => const [
            'laundry',
            'vacuum',
            'meal prep',
            'budget check-in',
            'call family',
          ],

        CategoryType.monthly => const [
            'deep clean',
            'organize closet',
            'review goals',
            'schedule appointments',
            'reset budget',
          ],
      };

  String get setupFrequencyNote => switch (this) {
        CategoryType.daily => 'Daily.',
        CategoryType.weekly => 'Weekly.',
        CategoryType.monthly => 'Monthly.',
      };
}