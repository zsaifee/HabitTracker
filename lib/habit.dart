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

  Habit({
    required this.id,
    required this.name,
    required this.points,
    required this.category,
    this.rank = 0,
    this.isExercise = false,
    this.reasoning,
  });

  Map<String, dynamic> toJson() => {
        // keep id in body for backward compatibility
        'id': id,
        'name': name,
        'points': points,
        'isExercise': isExercise,
        'reasoning': reasoning,
        'category': category.key,
        'rank': rank,
      };

  static Habit fromJson(Map<String, dynamic> data) {
    final id = (data['id'] as String?) ?? '';
    final catKey =
        (data['category'] as String?) ?? CategoryType.wantToMaintain.key;

    return Habit(
      id: id,
      name: (data['name'] as String?) ?? '',
      points: (data['points'] as int?) ?? 1,
      isExercise: (data['isExercise'] as bool?) ?? false,
      reasoning: data['reasoning'] as String?,
      category: CategoryTypeX.fromKey(catKey),
      rank: (data['rank'] as int?) ?? 0,
    );
  }

  static Habit fromDoc(String id, Map<String, dynamic> data) {
    final catKey =
        (data['category'] as String?) ?? CategoryType.wantToMaintain.key;

    return Habit(
      id: id,
      name: (data['name'] as String?) ?? '',
      points: (data['points'] as int?) ?? 1,
      isExercise: (data['isExercise'] as bool?) ?? false,
      reasoning: data['reasoning'] as String?,
      category: CategoryTypeX.fromKey(catKey),
      rank: (data['rank'] as int?) ?? 0,
    );
  }
}
