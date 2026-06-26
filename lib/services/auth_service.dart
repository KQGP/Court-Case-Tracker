import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/index.dart';

class AuthService {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isJudge => _currentUser?.role == 'judge';
  bool get isClerk => _currentUser?.role == 'clerk';

  bool hasPermission(String permission) {
    return _currentUser?.permissions[permission] ?? false;
  }

  // Login by looking up user credentials in Firestore
  // Since there's no Firebase Auth password, we use a simple name-based login
  // for demo purposes. The admin can log in with a predefined admin ID.
  Future<UserModel?> login(String userId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    final user = UserModel.fromFirestore(doc);
    if (!user.active) return null;
    _currentUser = user;
    return user;
  }

  // Simple login by name (for demo/dev)
  Future<UserModel?> loginByName(String name) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('name', isEqualTo: name)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final user = UserModel.fromFirestore(snap.docs.first);
    if (!user.active) return null;
    _currentUser = user;
    return user;
  }

  void logout() {
    _currentUser = null;
  }
}
