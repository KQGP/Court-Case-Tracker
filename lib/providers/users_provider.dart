import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import 'service_providers.dart';

final usersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getUsers();
});

final judgesProvider = Provider<AsyncValue<List<UserModel>>>((ref) {
  final users = ref.watch(usersStreamProvider);
  return users.whenData(
    (list) => list.where((u) => u.role == 'judge' && u.active).toList(),
  );
});

final clerksProvider = Provider<AsyncValue<List<UserModel>>>((ref) {
  final users = ref.watch(usersStreamProvider);
  return users.whenData(
    (list) => list.where((u) => u.role == 'clerk' && u.active).toList(),
  );
});
