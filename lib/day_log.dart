class DayLog {
  final String dateKey; // YYYY-MM-DD
  String note;
  Set<String> completedHabitIds;

  DayLog({
    required this.dateKey,
    this.note = '',
    Set<String>? completedHabitIds,
  }) : completedHabitIds = completedHabitIds ?? <String>{};

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'note': note,
        'completedHabitIds': completedHabitIds.toList(),
      };

  static DayLog fromJson(Map<String, dynamic> json) => DayLog(
        dateKey: json['dateKey'] as String,
        note: (json['note'] as String?) ?? '',
        completedHabitIds: Set<String>.from(
          (json['completedHabitIds'] as List<dynamic>? ?? const []).map((e) => e as String),
        ),
      );
}