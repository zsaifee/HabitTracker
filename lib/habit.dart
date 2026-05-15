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

  
  bool oneAndDone; // not used anymore

  String? lastCompletedDate;



  Habit({
    required this.id,
    required this.name,
    required this.points,
    required this.category,
    this.rank = 0,
    this.isExercise = false,
    this.reasoning,
    this.lastCompletedDate,
    bool? oneAndDone,
  }) : oneAndDone = oneAndDone ?? _defaultOneAndDone(category);


  static int defaultPointsForCategory(CategoryType c) {
    switch (c) {
      case CategoryType.monthly:
        return 5;
      case CategoryType.weekly:
        return 3;
      case CategoryType.daily:
        return 2;
      case CategoryType.custom:
        return 1;
    }
  }

  static int clampPoints(int v) => v.clamp(1, 10);

  /// Default rule: treat "to do’s you’ve been putting off" as one-and-done.
  static bool _defaultOneAndDone(CategoryType c) {
    return c == CategoryType.daily;
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
    String? lastCompletedDate,
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
      oneAndDone: oneAndDone ?? _defaultOneAndDone(newCategory), // not used anymore
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
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
        'lastCompletedDate': lastCompletedDate,
      };

  static Habit fromJson(Map<String, dynamic> data) {
    final id = (data['id'] as String?) ?? '';
    final catKey =
        (data['category'] as String?) ?? CategoryType.monthly.key;

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
      lastCompletedDate: data['lastCompletedDate'] as String?, 
    );
  }

  static Habit fromDoc(String id, Map<String, dynamic> data) {
    // Your Firestore docs may not store id in the body; doc id is truth.
    final catKey =
        (data['category'] as String?) ?? CategoryType.weekly.key;

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
      lastCompletedDate: data['lastCompletedDate'] as String?,
    );
  }
}
