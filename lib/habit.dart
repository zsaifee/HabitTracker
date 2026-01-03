// ==============================
// habit.dart
// ==============================

import 'category_type.dart';

class Habit {
  String id;
  String name;

  /// 1–10 points (defaults depend on category, but user can override)
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

  // =========================
  // Defaults (your system)
  // =========================

  /// Default point values by category:
  /// - put off todos (avoided tasks): 5
  /// - feel good irregular (amazing when done): 3
  /// - want to start (building habits): 2
  /// - want to maintain (protect routines): 1
  static int defaultPointsForCategory(CategoryType c) {
    switch (c) {
      case CategoryType.putOffTodos:
        return 5;
      case CategoryType.feelGoodIrregular:
        return 3;
      case CategoryType.wantToStart:
        return 2;
      case CategoryType.wantToMaintain:
        return 1;
    }
  }

  static int clampPoints(int v) => v.clamp(1, 10);

  /// Default rule: treat "to do’s you’ve been putting off" as one-and-done.
  static bool _defaultOneAndDone(CategoryType c) {
    return c == CategoryType.putOffTodos;
  }

  Habit copyWith({
    String? id,
    String? name,
    int? points,
    bool? isExercise,
    String? reasoning,
    CategoryType? category,
    int? rank,
    bool? oneAndDone,
  }) {
    final newCategory = category ?? this.category;

    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      points: clampPoints(points ?? this.points),
      isExercise: isExercise ?? this.isExercise,
      reasoning: reasoning ?? this.reasoning,
      category: newCategory,
      rank: rank ?? this.rank,
      // If explicitly provided, respect it. Otherwise default based on category.
      oneAndDone: oneAndDone ?? _defaultOneAndDone(newCategory),
    );
  }

  Map<String, dynamic> toJson() => {
        // keep id in body for backward compatibility
        'id': id,
        'name': name,
        'points': clampPoints(points),
        'isExercise': isExercise,
        'reasoning': reasoning,
        'category': category.key,
        'rank': rank,
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
    final resolvedOneAndDone = storedOneAndDone is bool
        ? storedOneAndDone
        : _defaultOneAndDone(category);

    // Backward compatible points:
    // - If points exists, use it.
    // - Otherwise use default for category.
    final rawPoints = data['points'];
    final resolvedPoints = (rawPoints is int)
        ? rawPoints
        : defaultPointsForCategory(category);

    return Habit(
      id: id,
      name: (data['name'] as String?) ?? '',
      points: clampPoints(resolvedPoints),
      isExercise: (data['isExercise'] as bool?) ?? false,
      reasoning: data['reasoning'] as String?,
      category: category,
      rank: (data['rank'] as int?) ?? 0,
      oneAndDone: resolvedOneAndDone,
    );
  }

  static Habit fromDoc(String id, Map<String, dynamic> data) {
    // Your Firestore docs may not store id in the body; doc id is truth.
    final catKey =
        (data['category'] as String?) ?? CategoryType.wantToMaintain.key;

    final category = CategoryTypeX.fromKey(catKey);

    final storedOneAndDone = data['oneAndDone'];
    final resolvedOneAndDone = storedOneAndDone is bool
        ? storedOneAndDone
        : _defaultOneAndDone(category);

    final rawPoints = data['points'];
    final resolvedPoints = (rawPoints is int)
        ? rawPoints
        : defaultPointsForCategory(category);

    return Habit(
      id: id,
      name: (data['name'] as String?) ?? '',
      points: clampPoints(resolvedPoints),
      isExercise: (data['isExercise'] as bool?) ?? false,
      reasoning: data['reasoning'] as String?,
      category: category,
      rank: (data['rank'] as int?) ?? 0,
      oneAndDone: resolvedOneAndDone,
    );
  }
}
