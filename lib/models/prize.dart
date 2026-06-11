import 'package:cloud_firestore/cloud_firestore.dart';

class Prize {
  final String id;
  final String name;
  final String? description;
  final int cost;
  final String? emoji;
  final bool active;
  final int sortOrder;

  Prize({
    required this.id,
    required this.name,
    this.description,
    required this.cost,
    this.emoji,
    this.active = true,
    this.sortOrder = 0,
  });

  factory Prize.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Prize(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      cost: data['cost'] ?? 0,
      emoji: data['emoji'],
      active: data['active'] ?? true,
      sortOrder: data['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'cost': cost,
        'emoji': emoji,
        'active': active,
        'sortOrder': sortOrder,
      };
}
