import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());

final sessionServiceProvider = Provider<SessionService>((ref) => SessionService());
