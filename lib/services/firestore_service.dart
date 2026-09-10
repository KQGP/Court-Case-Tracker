import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/index.dart';
import 'offline_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final OfflineService _offline = OfflineService();

  // Checks current connectivity.
  Future<bool> hasConnection() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  // Writes either directly (online) or queues the operation (offline).
  // Returns true when written directly, false when queued for later sync.
  Future<bool> _write({
    required String operation,
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
    String userRole = '',
  }) async {
    if (await hasConnection()) {
      switch (operation) {
        case 'add':
          await _db.collection(collection).doc(docId).set(data);
          break;
        case 'update':
          await _db.collection(collection).doc(docId).set(data, SetOptions(merge: true));
          break;
        case 'delete':
          await _db.collection(collection).doc(docId).delete();
          break;
      }
      return true;
    } else {
      await _offline.enqueueOperation(
        operation: operation,
        collection: collection,
        docId: docId,
        data: data,
        userRole: userRole,
      );
      return false;
    }
  }

  // Processes any pending offline operations if we are back online.
  Future<void> syncPendingOperations() async {
    if (!await hasConnection()) return;
    await _offline.processQueue();
  }

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

  Future<void> addUser(UserModel user) async {
    await _write(
      operation: 'add',
      collection: 'users',
      docId: user.id,
      data: user.toFirestore(),
    );
  }

  Future<void> updateUser(String id, UserModel user) async {
    await _write(
      operation: 'update',
      collection: 'users',
      docId: id,
      data: user.toFirestore(),
    );
  }

  Future<void> deleteUser(String id) async {
    await _write(operation: 'delete', collection: 'users', docId: id, data: {});
  }

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

  Future<void> addCase(CaseModel c) async {
    await _write(
      operation: 'add',
      collection: 'cases',
      docId: c.id,
      data: c.toFirestore(),
    );
  }

  Future<void> updateCase(String id, CaseModel c) async {
    await _write(
      operation: 'update',
      collection: 'cases',
      docId: id,
      data: c.toFirestore(),
    );
  }

  Future<void> deleteCase(String id) async {
    await _write(operation: 'delete', collection: 'cases', docId: id, data: {});
  }

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

  Future<void> addTransfer(TransferModel t) async {
    await _write(
      operation: 'add',
      collection: 'transfers',
      docId: t.id,
      data: t.toFirestore(),
    );
  }

  Future<void> updateTransfer(String id, TransferModel t) async {
    await _write(
      operation: 'update',
      collection: 'transfers',
      docId: id,
      data: t.toFirestore(),
    );
  }

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

  Future<void> addSession(SessionModel s) async {
    await _write(
      operation: 'add',
      collection: 'sessions',
      docId: s.id,
      data: s.toFirestore(),
    );
  }

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

  Future<void> addHistory(HistoryModel h) async {
    await _write(
      operation: 'add',
      collection: 'history',
      docId: h.id,
      data: h.toFirestore(),
    );
  }

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

  Future<void> addNotification(NotificationModel n) async {
    await _write(
      operation: 'add',
      collection: 'notifications',
      docId: n.id,
      data: n.toFirestore(),
    );
  }

  Future<void> markNotificationRead(String id) async {
    await _db.collection('notifications').doc(id).update({'read': true});
  }

  // MARK: - Settings
  Future<Map<String, dynamic>> getSettings() async {
    final snap = await _db.collection('settings').doc('app_settings').get();
    return snap.data() ?? {};
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    await _write(
      operation: 'update',
      collection: 'settings',
      docId: 'app_settings',
      data: settings,
    );
  }
}
