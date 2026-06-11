import 'package:flutter/material.dart';
import '../models/app_user.dart';
import 'firestore_service.dart';

class SessionProvider extends ChangeNotifier {
  final FirestoreService _db = FirestoreService();
  AppUser? _currentUser;
  List<AppUser> _allUsers = [];
  bool _loading = true;

  AppUser? get currentUser => _currentUser;
  List<AppUser> get allUsers => _allUsers;
  List<AppUser> get children =>
      _allUsers.where((u) => u.role == UserRole.child).toList();
  List<AppUser> get parents =>
      _allUsers.where((u) => u.role == UserRole.parent).toList();
  bool get loading => _loading;
  bool get isLoggedIn => _currentUser != null;
  bool get isParent => _currentUser?.role == UserRole.parent;

  Future<void> loadUsers() async {
    _loading = true;
    notifyListeners();
    _allUsers = await _db.getUsers();
    _loading = false;
    notifyListeners();
  }

  Future<bool> login(String userId, String pin) async {
    final user = await _db.getUserById(userId);
    if (user != null && user.pin == pin) {
      _currentUser = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  /// Refresh current user from Firestore (e.g. after avatar change).
  Future<void> refreshCurrentUser() async {
    if (_currentUser == null) return;
    final updated = await _db.getUserById(_currentUser!.id);
    if (updated != null) {
      _currentUser = updated;
      notifyListeners();
    }
  }

  Future<bool> hasFamilyData() => _db.hasFamilyData();

  Future<void> seedFamily({
    required String parentName,
    required String parentPin,
    required List<Map<String, String>> children,
  }) async {
    await _db.seedFamily(
      parentName: parentName,
      parentPin: parentPin,
      children: children,
    );
    await loadUsers();
  }
}
