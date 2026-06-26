import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String id;
  final String caseId;
  final DateTime sessionDate;
  final DateTime? nextSessionDate;
  final String operation;
  final String result;
  final String notes;
  final String createdBy;
  final DateTime createdAt;

  SessionModel({
    required this.id,
    required this.caseId,
    required this.sessionDate,
    this.nextSessionDate,
    this.operation = '',
    this.result = '',
    this.notes = '',
    this.createdBy = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SessionModel(
      id: doc.id,
      caseId: data['caseId'] ?? '',
      sessionDate: (data['sessionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      nextSessionDate: (data['nextSessionDate'] as Timestamp?)?.toDate(),
      operation: data['operation'] ?? '',
      result: data['result'] ?? '',
      notes: data['notes'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'caseId': caseId,
      'sessionDate': Timestamp.fromDate(sessionDate),
      'nextSessionDate': nextSessionDate != null ? Timestamp.fromDate(nextSessionDate!) : null,
      'operation': operation,
      'result': result,
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
