class Habit {
  final String id;
  String name;
  int points;
  String? reasoning;
  bool isExercise;

  Habit({
    required this.id,
    required this.name,
    required this.points,
    this.reasoning,
    this.isExercise = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'points': points,
        'reasoning': reasoning,
        'isExercise': isExercise,
      };

  static Habit fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] as String,
        name: json['name'] as String,
        points: (json['points'] as num).toInt(),
        reasoning: json['reasoning'] as String?,
        isExercise: (json['isExercise'] as bool?) ?? false,
      );
}
