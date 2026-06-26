import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/index.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // MARK: - Users
  CollectionReference<UserModel> get _users =>
      _db.collection('users').withConverter(
            fromFirestore: (snap, _) => UserModel.fromFirestore(snap),
            toFirestore: (user, _) => user.toFirestore(),
          );

  Stream<List<UserModel>> getUsers() =>
      _users.snapshots().map((snap) => snap.docs.map((d) => d.data()).toList());

  Future<UserModel?> getUser(String id) async {
    final doc = await _users.doc(id).get();
    return doc.data();
  }

  Future<void> addUser(UserModel user) => _users.doc(user.id).set(user);

  Future<void> updateUser(String id, UserModel user) =>
      _users.doc(id).set(user);

  Future<void> deleteUser(String id) => _users.doc(id).delete();

  // MARK: - Cases
  CollectionReference<CaseModel> get _cases =>
      _db.collection('cases').withConverter(
            fromFirestore: (snap, _) => CaseModel.fromFirestore(snap),
            toFirestore: (c, _) => c.toFirestore(),
          );

  Stream<List<CaseModel>> getCases() =>
      _cases.snapshots().map((snap) => snap.docs.map((d) => d.data()).toList());

  Future<CaseModel?> getCase(String id) async {
    final doc = await _cases.doc(id).get();
    return doc.data();
  }

  Future<void> addCase(CaseModel c) => _cases.doc(c.id).set(c);

  Future<void> updateCase(String id, CaseModel c) =>
      _cases.doc(id).set(c);

  Future<void> deleteCase(String id) => _cases.doc(id).delete();

  // MARK: - Transfers
  CollectionReference<TransferModel> get _transfers =>
      _db.collection('transfers').withConverter(
            fromFirestore: (snap, _) => TransferModel.fromFirestore(snap),
            toFirestore: (t, _) => t.toFirestore(),
          );

  Stream<List<TransferModel>> getTransfers(String caseId) =>
      _transfers.where('caseId', isEqualTo: caseId).orderBy('createdAt', descending: true).snapshots().map(
            (snap) => snap.docs.map((d) => d.data()).toList(),
          );

  Future<void> addTransfer(TransferModel t) =>
      _transfers.doc(t.id).set(t);

  Future<void> updateTransfer(String id, TransferModel t) =>
      _transfers.doc(id).set(t);

  // MARK: - Sessions
  CollectionReference<SessionModel> get _sessions =>
      _db.collection('sessions').withConverter(
            fromFirestore: (snap, _) => SessionModel.fromFirestore(snap),
            toFirestore: (s, _) => s.toFirestore(),
          );

  Stream<List<SessionModel>> getSessions(String caseId) =>
      _sessions.where('caseId', isEqualTo: caseId).orderBy('sessionDate', descending: true).snapshots().map(
            (snap) => snap.docs.map((d) => d.data()).toList(),
          );

  Future<void> addSession(SessionModel s) =>
      _sessions.doc(s.id).set(s);

  // MARK: - History
  CollectionReference<HistoryModel> get _history =>
      _db.collection('history').withConverter(
            fromFirestore: (snap, _) => HistoryModel.fromFirestore(snap),
            toFirestore: (h, _) => h.toFirestore(),
          );

  Stream<List<HistoryModel>> getHistory(String caseId) =>
      _history.where('caseId', isEqualTo: caseId).orderBy('timestamp', descending: true).snapshots().map(
            (snap) => snap.docs.map((d) => d.data()).toList(),
          );

  Future<void> addHistory(HistoryModel h) =>
      _history.doc(h.id).set(h);

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

  // MARK: - Settings
  Future<Map<String, dynamic>> getSettings() async {
    final snap = await _db.collection('settings').doc('app_settings').get();
    return snap.data() ?? {};
  }

  Future<void> updateSettings(Map<String, dynamic> settings) =>
      _db.collection('settings').doc('app_settings').set(settings);
}
