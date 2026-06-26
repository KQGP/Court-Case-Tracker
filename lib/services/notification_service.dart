import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // MARK: - Notifications
  CollectionReference<NotificationModel> get _notifications =>
      _db.collection('notifications').withConverter(
            fromFirestore: (snap, _) => NotificationModel.fromFirestore(snap),
            toFirestore: (n, _) => n.toFirestore(),
          );

  Stream<List<NotificationModel>> getNotifications(String userId) =>
      _notifications.where('userId', isEqualTo: userId).orderBy('createdAt', descending: true).snapshots().map(
            (snap) => snap.docs.map((d) => d.data()).toList(),
          );

  Future<void> addNotification(NotificationModel n) =>
      _notifications.doc(n.id).set(n);

  Future<void> markNotificationRead(String id) =>
      _notifications.doc(id).update({'read': true});

  Future<void> deleteNotification(String id) =>
      _notifications.doc(id).delete();

  // Generate notification ID
  String generateNotificationId() {
    return 'notif_${DateTime.now().millisecondsSinceEpoch}_${_db.collection('notifications').doc().id}';
  }

  // Create different types of notifications
  NotificationModel createTransferNotification({
    required String userId,
    required String caseId,
    required String caseNumber,
    required String caseSummary,
    required String holderName,
    required String fromUserName,
    required String toUserName,
    required String type,
  }) {
    return NotificationModel(
      id: generateNotificationId(),
      userId: userId,
      caseId: caseId,
      caseNumber: caseNumber,
      caseSummary: caseSummary,
      holderName: holderName,
      title: 'نقل ملف إلى $toUserName',
      body: 'تم نقل $caseNumber من قبل $fromUserName',
      read: false,
      type: type,
    );
  }

  NotificationModel createOverdueNotification({
    required String userId,
    required String caseId,
    required String caseNumber,
    required String caseSummary,
    required String holderName,
    required int daysHeld,
  }) {
    return NotificationModel(
      id: generateNotificationId(),
      userId: userId,
      caseId: caseId,
      caseNumber: caseNumber,
      caseSummary: caseSummary,
      holderName: holderName,
      title: 'تنبيه: ملف بقي لفترة طويلة',
      body: '$caseNumber بقي عند $holderName لمدة $daysHeld يوم',
      read: false,
      type: 'overdue',
    );
  }

  NotificationModel createSessionNotification({
    required String userId,
    required String caseId,
    required String caseNumber,
    required String caseSummary,
    required String holderName,
    required DateTime sessionDate,
  }) {
    return NotificationModel(
      id: generateNotificationId(),
      userId: userId,
      caseId: caseId,
      caseNumber: caseNumber,
      caseSummary: caseSummary,
      holderName: holderName,
      title: 'جلسة قادمة قريبة',
      body: 'يوجد $caseNumber جلسة في ${_formatDate(sessionDate)} عند $holderName',
      read: false,
      type: 'session',
    );
  }

  NotificationModel createVerificationNotification({
    required String userId,
    required String caseId,
    required String caseNumber,
    required String caseSummary,
    required String fromUserName,
  }) {
    return NotificationModel(
      id: generateNotificationId(),
      userId: userId,
      caseId: caseId,
      caseNumber: caseNumber,
      caseSummary: caseSummary,
      holderName: '',
      title: 'يتطلب تأكيد الاستلام',
      body: '$fromUserName يطلب تأكيد استلام $caseNumber',
      read: false,
      type: 'verification',
    );
  }

  // Helper to format date
  static String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}
