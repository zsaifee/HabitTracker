// ==============================
// behavior.dart
// ==============================

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

  static Behavior fromDoc(String id, Map<String, dynamic> data) {
    final catKey =
        (data['category'] as String?) ?? CategoryType.wantToMaintain.key;

    return Behavior(
      id: id,
      name: (data['name'] as String?) ?? '',
      category: CategoryTypeX.fromKey(catKey),
      rank: (data['rank'] as int?) ?? 0,
    );
  }
}
