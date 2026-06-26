import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String caseId;
  final String caseNumber;
  final String caseSummary;
  final String holderName;
  final String title;
  final String body;
  final bool read;
  final String type; // 'transfer' | 'overdue' | 'session' | 'verification'
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.caseId,
    required this.caseNumber,
    required this.caseSummary,
    required this.holderName,
    required this.title,
    required this.body,
    this.read = false,
    required this.type,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      caseId: data['caseId'] ?? '',
      caseNumber: data['caseNumber'] ?? '',
      caseSummary: data['caseSummary'] ?? '',
      holderName: data['holderName'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      read: data['read'] ?? false,
      type: data['type'] ?? 'notification',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'caseId': caseId,
      'caseNumber': caseNumber,
      'caseSummary': caseSummary,
      'holderName': holderName,
      'title': title,
      'body': body,
      'read': read,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
