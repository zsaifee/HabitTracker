class Profile {
  final String id;
  String name;

  Profile({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  static Profile fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? 'profile',
      );
}
