import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryModel {
  final String id;
  final String caseId;
  final String type; // 'transfer', 'edit', 'statusChange', 'session', 'other'
  final String description;
  final String performedBy;
  final String performedByName;
  final String previousValue;
  final String newValue;
  final DateTime timestamp;

  HistoryModel({
    required this.id,
    required this.caseId,
    required this.type,
    required this.description,
    this.performedBy = '',
    this.performedByName = '',
    this.previousValue = '',
    this.newValue = '',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory HistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HistoryModel(
      id: doc.id,
      caseId: data['caseId'] ?? '',
      type: data['type'] ?? 'other',
      description: data['description'] ?? '',
      performedBy: data['performedBy'] ?? '',
      performedByName: data['performedByName'] ?? '',
      previousValue: data['previousValue'] ?? '',
      newValue: data['newValue'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'caseId': caseId,
      'type': type,
      'description': description,
      'performedBy': performedBy,
      'performedByName': performedByName,
      'previousValue': previousValue,
      'newValue': newValue,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
