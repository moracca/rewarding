import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { earned, redeemed, manualRedeem }

class DbuxTransaction {
  final String id;
  final String childId;
  final String childName;
  final int amount;
  final String description;
  final TransactionType type;
  final DateTime createdAt;
  final String createdBy;

  DbuxTransaction({
    required this.id,
    required this.childId,
    required this.childName,
    required this.amount,
    required this.description,
    required this.type,
    required this.createdAt,
    required this.createdBy,
  });

  factory DbuxTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DbuxTransaction(
      id: doc.id,
      childId: data['childId'] ?? '',
      childName: data['childName'] ?? '',
      amount: data['amount'] ?? 0,
      description: data['description'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransactionType.earned,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'childId': childId,
        'childName': childName,
        'amount': amount,
        'description': description,
        'type': type.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'createdBy': createdBy,
      };
}
