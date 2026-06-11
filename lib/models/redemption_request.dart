import 'package:cloud_firestore/cloud_firestore.dart';

enum RedemptionStatus { pending, approved, denied }

class RedemptionRequest {
  final String id;
  final String childId;
  final String childName;
  final String prizeId;
  final String prizeName;
  final int cost;
  final RedemptionStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  RedemptionRequest({
    required this.id,
    required this.childId,
    required this.childName,
    required this.prizeId,
    required this.prizeName,
    required this.cost,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
  });

  factory RedemptionRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RedemptionRequest(
      id: doc.id,
      childId: data['childId'] ?? '',
      childName: data['childName'] ?? '',
      prizeId: data['prizeId'] ?? '',
      prizeName: data['prizeName'] ?? '',
      cost: data['cost'] ?? 0,
      status: RedemptionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RedemptionStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      resolvedBy: data['resolvedBy'],
    );
  }

  Map<String, dynamic> toMap() => {
        'childId': childId,
        'childName': childName,
        'prizeId': prizeId,
        'prizeName': prizeName,
        'cost': cost,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
        'resolvedBy': resolvedBy,
      };
}
