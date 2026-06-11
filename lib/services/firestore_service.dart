import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/transaction.dart';
import '../models/prize.dart';
import '../models/redemption_request.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Family setup (first-run seed) ───
  CollectionReference get _users => _db.collection('users');
  CollectionReference get _transactions => _db.collection('transactions');
  CollectionReference get _prizes => _db.collection('prizes');
  CollectionReference get _redemptions => _db.collection('redemptions');

  // ─── Users ───
  Stream<List<AppUser>> get usersStream => _users.snapshots().map(
        (snap) => snap.docs.map((d) => AppUser.fromFirestore(d)).toList(),
      );

  Future<List<AppUser>> getUsers() async {
    final snap = await _users.get();
    return snap.docs.map((d) => AppUser.fromFirestore(d)).toList();
  }

  Future<AppUser?> getUserById(String id) async {
    final doc = await _users.doc(id).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  Stream<AppUser?> userStream(String id) =>
      _users.doc(id).snapshots().map((doc) {
        if (!doc.exists) return null;
        return AppUser.fromFirestore(doc);
      });

  Future<void> createUser(AppUser user) =>
      _users.doc(user.id).set(user.toMap());

  Future<void> updateBalance(String childId, int newBalance) =>
      _users.doc(childId).update({'balance': newBalance});

  // ─── Transactions ───
  Stream<List<DbuxTransaction>> transactionsStream({String? childId}) {
    return _transactions.orderBy('createdAt', descending: true).snapshots().map(
          (snap) {
        var list = snap.docs.map((d) => DbuxTransaction.fromFirestore(d)).toList();
        if (childId != null) {
          list = list.where((t) => t.childId == childId).toList();
        }
        return list;
      },
    );
  }

  Future<void> awardDbux({
    required String childId,
    required String childName,
    required int amount,
    required String description,
    required String awardedBy,
  }) async {
    final batch = _db.batch();

    // Create transaction record
    final txRef = _transactions.doc();
    batch.set(txRef, DbuxTransaction(
      id: txRef.id,
      childId: childId,
      childName: childName,
      amount: amount,
      description: description,
      type: TransactionType.earned,
      createdAt: DateTime.now(),
      createdBy: awardedBy,
    ).toMap());

    // Update balance
    batch.update(_users.doc(childId), {
      'balance': FieldValue.increment(amount),
    });

    await batch.commit();
  }

  Future<void> manualRedeem({
    required String childId,
    required String childName,
    required int amount,
    required String description,
    required String redeemedBy,
  }) async {
    final batch = _db.batch();

    final txRef = _transactions.doc();
    batch.set(txRef, DbuxTransaction(
      id: txRef.id,
      childId: childId,
      childName: childName,
      amount: amount,
      description: description,
      type: TransactionType.manualRedeem,
      createdAt: DateTime.now(),
      createdBy: redeemedBy,
    ).toMap());

    batch.update(_users.doc(childId), {
      'balance': FieldValue.increment(-amount),
    });

    await batch.commit();
  }

  // ─── Prizes ───
  Stream<List<Prize>> get prizesStream =>
      _prizes.snapshots().map(
            (snap) {
          final list = snap.docs.map((d) => Prize.fromFirestore(d)).toList();
          list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          return list;
        },
      );

  Future<void> reorderPrizes(List<Prize> prizes) async {
    final batch = _db.batch();
    for (int i = 0; i < prizes.length; i++) {
      batch.update(_prizes.doc(prizes[i].id), {'sortOrder': i});
    }
    await batch.commit();
  }

  Future<void> addPrize(Prize prize) => _prizes.doc(prize.id.isEmpty ? null : prize.id).set(prize.toMap());

  Future<String> createPrize(Prize prize) async {
    final ref = await _prizes.add(prize.toMap());
    return ref.id;
  }

  Future<void> updatePrize(String id, Map<String, dynamic> data) =>
      _prizes.doc(id).update(data);

  Future<void> deletePrize(String id) => _prizes.doc(id).delete();

  // ─── Redemption Requests ───
  Stream<List<RedemptionRequest>> redemptionsStream({
    String? childId,
    RedemptionStatus? status,
  }) {
    // Use a single orderBy and filter client-side to avoid
    // needing Firestore composite indexes for this small dataset.
    return _redemptions.orderBy('createdAt', descending: true).snapshots().map(
          (snap) {
        var list = snap.docs
            .map((d) => RedemptionRequest.fromFirestore(d))
            .toList();
        if (childId != null) {
          list = list.where((r) => r.childId == childId).toList();
        }
        if (status != null) {
          list = list.where((r) => r.status == status).toList();
        }
        return list;
      },
    );
  }

  Future<void> requestRedemption({
    required String childId,
    required String childName,
    required Prize prize,
  }) async {
    await _redemptions.add(RedemptionRequest(
      id: '',
      childId: childId,
      childName: childName,
      prizeId: prize.id,
      prizeName: prize.name,
      cost: prize.cost,
      status: RedemptionStatus.pending,
      createdAt: DateTime.now(),
    ).toMap());
  }

  Future<void> resolveRedemption({
    required String requestId,
    required RedemptionStatus status,
    required String resolvedBy,
    required String childId,
    required int cost,
    required String childName,
    required String prizeName,
  }) async {
    final batch = _db.batch();

    batch.update(_redemptions.doc(requestId), {
      'status': status.name,
      'resolvedAt': Timestamp.fromDate(DateTime.now()),
      'resolvedBy': resolvedBy,
    });

    if (status == RedemptionStatus.approved) {
      // Deduct balance
      batch.update(_users.doc(childId), {
        'balance': FieldValue.increment(-cost),
      });

      // Create transaction record
      final txRef = _transactions.doc();
      batch.set(txRef, DbuxTransaction(
        id: txRef.id,
        childId: childId,
        childName: childName,
        amount: cost,
        description: 'Redeemed: $prizeName',
        type: TransactionType.redeemed,
        createdAt: DateTime.now(),
        createdBy: resolvedBy,
      ).toMap());
    }

    await batch.commit();
  }

  // ─── First-run seed ───
  Future<bool> hasFamilyData() async {
    final snap = await _users.limit(1).get();
    return snap.docs.isNotEmpty;
  }

  Future<void> seedFamily({
    required String parentName,
    required String parentPin,
    required List<Map<String, String>> children,
  }) async {
    final batch = _db.batch();

    // Create parent
    final parentRef = _users.doc();
    batch.set(parentRef, {
      'name': parentName,
      'role': 'parent',
      'pin': parentPin,
      'avatarEmoji': '👨',
      'balance': 0,
    });

    // Create children
    for (final child in children) {
      final childRef = _users.doc();
      batch.set(childRef, {
        'name': child['name'],
        'role': 'child',
        'pin': child['pin'] ?? '0000',
        'avatarEmoji': child['emoji'] ?? '😊',
        'balance': 0,
      });
    }

    await batch.commit();
  }
}
