import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../models/index.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isJudge => _currentUser?.role == 'judge';
  bool get isClerk => _currentUser?.role == 'clerk';

  bool hasPermission(String permission) {
    return _currentUser?.permissions[permission] ?? false;
  }

  bool get isSignedIn => _auth.currentUser != null;

  // Sets the in-memory current user without touching Firebase Auth state.
  // Used on first-run setup right after creating the Auth account.
  void setCurrentUser(UserModel user) {
    _currentUser = user;
  }

  // Loads the profile document for an authenticated user.
  Future<UserModel?> _loadProfile(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final user = UserModel.fromFirestore(doc);
    if (!user.active) return null;
    return user;
  }

  Future<UserModel?> _fetchCurrentUser() async {
    final u = _auth.currentUser;
    if (u == null) return null;
    _currentUser = await _loadProfile(u.uid);
    return _currentUser;
  }

  // Restores the persisted Firebase Auth session on app startup (if any).
  Future<UserModel?> restoreSession() => _fetchCurrentUser();

  // Signs in with email + password, then loads the user profile.
  Future<UserModel?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          throw AuthException('البريد الإلكتروني أو كلمة المرور غير صحيحة');
        case 'too-many-requests':
          throw AuthException('محاولات كثيرة، حاول لاحقاً');
        default:
          throw AuthException('فشل تسجيل الدخول: ${e.message ?? e.code}');
      }
    }
    final user = await _fetchCurrentUser();
    if (user == null) {
      await logout();
      throw AuthException('لا يوجد حساب مرتبط بهذا البريد الإلكتروني');
    }
    return user;
  }

  // Creates a new Firebase Auth account and returns its UID.
  // The caller is responsible for writing the profile document.
  Future<String> register(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return cred.user!.uid;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw AuthException('البريد الإلكتروني مستخدم بالفعل');
        case 'weak-password':
          throw AuthException('كلمة المرور ضعيفة (6 أحرف على الأقل)');
        case 'invalid-email':
          throw AuthException('البريد الإلكتروني غير صالح');
        default:
          throw AuthException('فشل إنشاء الحساب: ${e.message ?? e.code}');
      }
    }
  }

  // Signs in with Google and returns the user profile. If the user has no
  // profile document yet, one is auto-created with the default 'clerk' role
  // (an admin can promote them later).
  Future<UserModel?> signInWithGoogle() async {
    final GoogleSignIn gsi = GoogleSignIn.instance;
    GoogleSignInAccount account;
    try {
      account = await gsi.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        throw AuthException('تم إلغاء تسجيل الدخول بواسطة Google');
      }
      throw AuthException('فشل تسجيل الدخول بواسطة Google: ${e.description}');
    }

    final credential = GoogleAuthProvider.credential(
      idToken: account.authentication.idToken,
    );

    try {
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException('فشل تسجيل الدخول بواسطة Google: ${e.message ?? e.code}');
    }

    final uid = _auth.currentUser!.uid;
    final email = _auth.currentUser!.email ?? '';

    var profile = await _loadProfile(uid);
    if (profile == null) {
      // First-time Google sign-in: create a default clerk profile.
      final defaultName = account.displayName?.trim().isNotEmpty == true
          ? account.displayName!.trim()
          : (email.split('@').first.isEmpty ? 'مستخدم' : email.split('@').first);
      profile = UserModel(
        id: uid,
        email: email,
        name: defaultName,
        role: 'clerk',
        active: true,
      );
      await FirebaseFirestore.instance.collection('users').doc(uid).set(profile.toFirestore());
    }

    _currentUser = profile;
    return profile;
  }

  Future<void> logout() async {
    _currentUser = null;
    await _auth.signOut();
    await GoogleSignIn.instance.signOut();
  }
}
