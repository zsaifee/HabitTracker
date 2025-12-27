class Goal {
  final String behaviorId;
  final int frequencyPerWeek;

  const Goal({
    required this.behaviorId,
    required this.frequencyPerWeek,
  });

  Map<String, dynamic> toMap() => {
        'frequencyPerWeek': frequencyPerWeek,
      };
}
