import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/index.dart';

class OfflineQueueItem {
  final String id;
  final String operation; // 'add', 'update', 'delete'
  final String collection;
  final String docId;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String userRole;
  final int retryCount;

  OfflineQueueItem({
    required this.id,
    required this.operation,
    required this.collection,
    required this.docId,
    required this.data,
    required this.timestamp,
    this.userRole = '',
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'operation': operation,
        'collection': collection,
        'docId': docId,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        'userRole': userRole,
        'retryCount': retryCount,
      };

  factory OfflineQueueItem.fromJson(Map<String, dynamic> json) =>
      OfflineQueueItem(
        id: json['id'] as String,
        operation: json['operation'] as String,
        collection: json['collection'] as String,
        docId: json['docId'] as String,
        data: Map<String, dynamic>.from(json['data']),
        timestamp: DateTime.parse(json['timestamp'] as String),
        userRole: json['userRole'] as String? ?? '',
        retryCount: json['retryCount'] as int? ?? 0,
      );

  OfflineQueueItem copyWith({int? retryCount}) {
    return OfflineQueueItem(
      id: id,
      operation: operation,
      collection: collection,
      docId: docId,
      data: data,
      timestamp: timestamp,
      userRole: userRole,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

class SyncConflict {
  final String collection;
  final String docId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime localTimestamp;
  final DateTime remoteTimestamp;
  final String resolution; // 'local', 'remote', 'merge'

  SyncConflict({
    required this.collection,
    required this.docId,
    required this.localData,
    required this.remoteData,
    required this.localTimestamp,
    required this.remoteTimestamp,
    this.resolution = '',
  });
}

class OfflineService {
  static const _queueBoxName = 'offline_queue';
  static const _localDataBoxName = 'local_data';

  final Uuid _uuid = const Uuid();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Box> get _queueBox async => await Hive.openBox(_queueBoxName);
  Future<Box> get _localDataBox async => await Hive.openBox(_localDataBoxName);

  // Check connectivity
  Future<bool> isConnected() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  // Queue an offline operation
  Future<void> enqueueOperation({
    required String operation,
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
    String userRole = '',
  }) async {
    final box = await _queueBox;
    final item = OfflineQueueItem(
      id: _uuid.v4(),
      operation: operation,
      collection: collection,
      docId: docId,
      data: data,
      timestamp: DateTime.now(),
      userRole: userRole,
    );
    await box.add(jsonEncode(item.toJson()));
  }

  // Get all queued operations
  Future<List<OfflineQueueItem>> getQueue() async {
    final box = await _queueBox;
    final items = <OfflineQueueItem>[];
    for (final value in box.values) {
      items.add(OfflineQueueItem.fromJson(jsonDecode(value as String)));
    }
    return items;
  }

  // Get queued operations together with their box keys (safe for removal)
  Future<List<MapEntry<int, OfflineQueueItem>>> getQueueWithKeys() async {
    final box = await _queueBox;
    final items = <MapEntry<int, OfflineQueueItem>>[];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is String) {
        items.add(MapEntry(key as int, OfflineQueueItem.fromJson(jsonDecode(value))));
      }
    }
    return items;
  }

  // Remove a completed queue item by its box key
  Future<void> removeQueueItem(int boxKey) async {
    final box = await _queueBox;
    if (box.containsKey(boxKey)) {
      await box.delete(boxKey);
    }
  }

  // Clear the entire queue
  Future<void> clearQueue() async {
    final box = await _queueBox;
    await box.clear();
  }

  // Process queue with conflict resolution
  Future<List<SyncConflict>> processQueue() async {
    final conflicts = <SyncConflict>[];
    final box = await _queueBox;
    final queue = await getQueueWithKeys();

    for (final entry in queue) {
      final boxKey = entry.key;
      final item = entry.value;

      try {
        switch (item.operation) {
          case 'add':
            await _db.collection(item.collection).doc(item.docId).set(item.data);
            break;

          case 'update':
            // Check for conflicts
            final remoteDoc = await _db.collection(item.collection).doc(item.docId).get();
            if (remoteDoc.exists) {
              final remoteData = remoteDoc.data()!;
              final remoteTimestamp = (remoteData['lastOperationDate'] as Timestamp?)?.toDate() ?? DateTime.now();
              final localTimestamp = item.timestamp;

              if (_hasConflict(item, remoteData, localTimestamp, remoteTimestamp)) {
                final resolution = _resolveConflict(item, remoteData, localTimestamp, remoteTimestamp);
                conflicts.add(SyncConflict(
                  collection: item.collection,
                  docId: item.docId,
                  localData: item.data,
                  remoteData: remoteData,
                  localTimestamp: localTimestamp,
                  remoteTimestamp: remoteTimestamp,
                  resolution: resolution,
                ));

                if (resolution == 'remote') {
                  // Remote wins, drop the local update
                  await removeQueueItem(boxKey);
                  continue;
                }
              }
            }
            await _db.collection(item.collection).doc(item.docId).set(item.data, SetOptions(merge: true));
            break;

          case 'delete':
            await _db.collection(item.collection).doc(item.docId).delete();
            break;
        }
        await removeQueueItem(boxKey);
      } catch (e) {
        // Retry up to 3 times
        if (item.retryCount < 3) {
          final updatedItem = item.copyWith(retryCount: item.retryCount + 1);
          await box.put(boxKey, jsonEncode(updatedItem.toJson()));
        } else {
          // Remove after max retries (keeps the queue from blocking forever)
          await removeQueueItem(boxKey);
        }
      }
    }

    return conflicts;
  }

  bool _hasConflict(
    OfflineQueueItem item,
    Map<String, dynamic> remoteData,
    DateTime localTime,
    DateTime remoteTime,
  ) {
    if (remoteTime.isAfter(localTime)) {
      final remoteRole = remoteData['lastOperationByRole'] as String? ?? '';
      final localRole = item.userRole;

      // Judge overrides clerk
      if (localRole == 'clerk' && remoteRole == 'judge') return false;
      if (localRole == 'judge' && remoteRole == 'clerk') return true;

      // Same level = first commit wins (remote was first)
      return remoteTime.isAfter(localTime.add(const Duration(seconds: 5)));
    }
    return false;
  }

  String _resolveConflict(
    OfflineQueueItem item,
    Map<String, dynamic> remoteData,
    DateTime localTime,
    DateTime remoteTime,
  ) {
    final remoteRole = remoteData['lastOperationByRole'] as String? ?? '';
    final localRole = item.userRole;

    // Judge always wins
    if (localRole == 'judge' && remoteRole != 'judge') return 'local';
    if (remoteRole == 'judge' && localRole != 'judge') return 'remote';

    // Clerk conflicts with clerk = first commit wins
    if (remoteTime.isAfter(localTime.add(const Duration(seconds: 5)))) {
      return 'remote';
    }

    return 'local';
  }

  // Store data locally for offline access
  Future<void> storeLocalData(String key, dynamic data) async {
    final box = await _localDataBox;
    await box.put(key, data);
  }

  // Retrieve local data
  Future<dynamic> getLocalData(String key) async {
    final box = await _localDataBox;
    return box.get(key);
  }

  // Remove local data
  Future<void> removeLocalData(String key) async {
    final box = await _localDataBox;
    await box.delete(key);
  }

  // Cache cases list locally
  Future<void> cacheCases(List<CaseModel> cases) async {
    final data = cases.map((c) => c.toFirestore()).toList();
    await storeLocalData('cached_cases', data);
    await storeLocalData('cached_cases_time', DateTime.now().toIso8601String());
  }

  // Get cached cases
  Future<List<CaseModel>> getCachedCases() async {
    final data = await getLocalData('cached_cases');
    if (data == null) return [];
    return (data as List).map((e) {
      return CaseModel(
        id: e['id'] ?? '',
        caseNumber: e['caseNumber'] ?? '',
        year: e['year'] ?? '',
        category: e['category'] ?? 'other',
        caseSummary: e['caseSummary'] ?? '',
        partyOneName: e['partyOneName'] ?? '',
        partyOnePersons: e['partyOnePersons'] != null ? List<String>.from(e['partyOnePersons']) : [],
        partyTwoName: e['partyTwoName'] ?? '',
        partyTwoPersons: e['partyTwoPersons'] != null ? List<String>.from(e['partyTwoPersons']) : [],
        status: e['status'] ?? 'active',
        currentHolder: e['currentHolder'] ?? '',
        currentHolderType: e['currentHolderType'] ?? '',
        currentHolderName: e['currentHolderName'] ?? '',
        assignedJudgeId: e['assignedJudgeId'] ?? '',
        assignedJudgeName: e['assignedJudgeName'] ?? '',
        assignedClerkId: e['assignedClerkId'] ?? '',
        assignedClerkName: e['assignedClerkName'] ?? '',
        lastOperation: e['lastOperation'] ?? '',
        lastOperationBy: e['lastOperationBy'] ?? '',
        location: e['location'] ?? 'dataCenter',
        createdAt: DateTime.now(),
        createdBy: e['createdBy'] ?? '',
      );
    }).toList();
  }

  // Cache users list locally
  Future<void> cacheUsers(List<UserModel> users) async {
    final data = users.map((u) => u.toFirestore()).toList();
    await storeLocalData('cached_users', data);
  }

  // Get cached users
  Future<List<UserModel>> getCachedUsers() async {
    final data = await getLocalData('cached_users');
    if (data == null) return [];
    return (data as List).map((e) {
      return UserModel(
        id: e['id'] ?? '',
        email: e['email'] ?? '',
        name: e['name'] ?? '',
        role: e['role'] ?? 'clerk',
        department: e['department'] ?? '',
        active: e['active'] ?? true,
        permissions: e['permissions'] != null ? Map<String, bool>.from(e['permissions']) : {},
        createdAt: DateTime.now(),
        createdBy: e['createdBy'] ?? '',
      );
    }).toList();
  }

  // Get queue count
  Future<int> getQueueCount() async {
    final queue = await getQueue();
    return queue.length;
  }
}
