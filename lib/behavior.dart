import 'category_type.dart';

class Behavior {
  final String id;
  final String name;
  final CategoryType category;
  final int rank;

  const Behavior({
    required this.id,
    required this.name,
    required this.category,
    required this.rank,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category.key,
        'rank': rank,
      };
}
