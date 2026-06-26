import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import 'service_providers.dart';

final notificationsProvider = StreamProvider.family<List<NotificationModel>, String>((ref, userId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getNotifications(userId);
});

final unreadNotificationsCountProvider = StreamProvider.family<int, String>((ref, userId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getNotifications(userId).map(
    (list) => list.where((n) => !n.read).length,
  );
});
