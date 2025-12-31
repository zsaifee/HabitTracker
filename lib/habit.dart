// ==============================
// habit.dart
// ==============================

import 'category_type.dart';

class Habit {
  String id;
  String name;

  int points;
  bool isExercise;
  String? reasoning;

  CategoryType category;
  int rank;

  /// If true, this is a "one and done" item (e.g. a put-off todo).
  /// Once completed, it should be removed from the point menu (deleted or archived).
  bool oneAndDone;

  Habit({
    required this.id,
    required this.name,
    required this.points,
    required this.category,
    this.rank = 0,
    this.isExercise = false,
    this.reasoning,
    bool? oneAndDone,
  }) : oneAndDone = oneAndDone ?? _defaultOneAndDone(category);

  /// Default rule: treat "to do’s you’ve been putting off" as one-and-done.
  /// Adjust this if your enum key is different.
  static bool _defaultOneAndDone(CategoryType c) {
    return c == CategoryType.putOffTodos;
  }

  Map<String, dynamic> toJson() => {
        // keep id in body for backward compatibility
        'id': id,
        'name': name,
        'points': points,
        'isExercise': isExercise,
        'reasoning': reasoning,
        'category': category.key,
        'rank': rank,

        // NEW
        'oneAndDone': oneAndDone,
      };

  static Habit fromJson(Map<String, dynamic> data) {
    final id = (data['id'] as String?) ?? '';
    final catKey =
        (data['category'] as String?) ?? CategoryType.wantToMaintain.key;

    final category = CategoryTypeX.fromKey(catKey);

    // Backward compatible:
    // - If oneAndDone exists, use it.
    // - Otherwise infer from category (putOffTodos => true).
    final storedOneAndDone = data['oneAndDone'];
    final oneAndDone = storedOneAndDone is bool
        ? storedOneAndDone
        : _defaultOneAndDone(category);

    return Habit(
      id: id,
      name: (data['name'] as String?) ?? '',
      points: (data['points'] as int?) ?? 1,
      isExercise: (data['isExercise'] as bool?) ?? false,
      reasoning: data['reasoning'] as String?,
      category: category,
      rank: (data['rank'] as int?) ?? 0,

      // NEW
      oneAndDone: oneAndDone,
    );
  }

  static Habit fromDoc(String id, Map<String, dynamic> data) {
    final catKey =
        (data['category'] as String?) ?? CategoryType.wantToMaintain.key;

    final category = CategoryTypeX.fromKey(catKey);

    // Backward compatible:
    final storedOneAndDone = data['oneAndDone'];
    final oneAndDone = storedOneAndDone is bool
        ? storedOneAndDone
        : _defaultOneAndDone(category);

    return Habit(
      id: id,
      name: (data['name'] as String?) ?? '',
      points: (data['points'] as int?) ?? 1,
      isExercise: (data['isExercise'] as bool?) ?? false,
      reasoning: data['reasoning'] as String?,
      category: category,
      rank: (data['rank'] as int?) ?? 0,

      // NEW
      oneAndDone: oneAndDone,
    );
  }
}
