import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/index.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StateProvider<UserModel?>((ref) => null);

final isLoggedInProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider);
  return user != null;
});

final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider);
  return user?.role == 'admin';
});

final currentUserRoleProvider = Provider<String?>((ref) {
  final user = ref.watch(authStateProvider);
  return user?.role;
});

final hasPermissionProvider = Provider.family<bool, String>((ref, permission) {
  final user = ref.watch(authStateProvider);
  return user?.permissions[permission] ?? false;
});
