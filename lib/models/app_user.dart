import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { parent, child }

class AppUser {
  final String id;
  final String name;
  final UserRole role;
  final String pin;
  final String? avatarEmoji;
  final int balance; // only relevant for children

  AppUser({
    required this.id,
    required this.name,
    required this.role,
    required this.pin,
    this.avatarEmoji,
    this.balance = 0,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      name: data['name'] ?? '',
      role: data['role'] == 'parent' ? UserRole.parent : UserRole.child,
      pin: data['pin'] ?? '',
      avatarEmoji: data['avatarEmoji'],
      balance: data['balance'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'role': role == UserRole.parent ? 'parent' : 'child',
        'pin': pin,
        'avatarEmoji': avatarEmoji,
        'balance': balance,
      };

  AppUser copyWith({
    String? name,
    UserRole? role,
    String? pin,
    String? avatarEmoji,
    int? balance,
  }) =>
      AppUser(
        id: id,
        name: name ?? this.name,
        role: role ?? this.role,
        pin: pin ?? this.pin,
        avatarEmoji: avatarEmoji ?? this.avatarEmoji,
        balance: balance ?? this.balance,
      );
}
