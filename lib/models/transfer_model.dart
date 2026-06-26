import 'package:cloud_firestore/cloud_firestore.dart';

class TransferModel {
  final String id;
  final String caseId;

  final String fromUserId;
  final String fromUserName;
  final String fromUserRole;

  final String toUserId;
  final String toUserName;
  final String toUserRole;

  final String type; // 'toJudge', 'toDataCenter', 'toClerk'

  final DateTime givenAt;
  final DateTime? returnedAt;
  final int periodDays;

  final bool verified;
  final DateTime? verifiedAt;
  final String verifiedBy;

  final String notes;
  final DateTime createdAt;

  TransferModel({
    required this.id,
    required this.caseId,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserRole = '',
    required this.toUserId,
    required this.toUserName,
    this.toUserRole = '',
    required this.type,
    DateTime? givenAt,
    this.returnedAt,
    this.periodDays = 0,
    this.verified = false,
    this.verifiedAt,
    this.verifiedBy = '',
    this.notes = '',
    DateTime? createdAt,
  })  : givenAt = givenAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  bool get isReturned => returnedAt != null;

  factory TransferModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransferModel(
      id: doc.id,
      caseId: data['caseId'] ?? '',
      fromUserId: data['fromUserId'] ?? '',
      fromUserName: data['fromUserName'] ?? '',
      fromUserRole: data['fromUserRole'] ?? '',
      toUserId: data['toUserId'] ?? '',
      toUserName: data['toUserName'] ?? '',
      toUserRole: data['toUserRole'] ?? '',
      type: data['type'] ?? '',
      givenAt: (data['givenAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      returnedAt: (data['returnedAt'] as Timestamp?)?.toDate(),
      periodDays: data['periodDays'] ?? 0,
      verified: data['verified'] ?? false,
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
      verifiedBy: data['verifiedBy'] ?? '',
      notes: data['notes'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'caseId': caseId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserRole': fromUserRole,
      'toUserId': toUserId,
      'toUserName': toUserName,
      'toUserRole': toUserRole,
      'type': type,
      'givenAt': Timestamp.fromDate(givenAt),
      'returnedAt': returnedAt != null ? Timestamp.fromDate(returnedAt!) : null,
      'periodDays': periodDays,
      'verified': verified,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'verifiedBy': verifiedBy,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  TransferModel copyWith({
    DateTime? returnedAt,
    int? periodDays,
    bool? verified,
    DateTime? verifiedAt,
    String? verifiedBy,
    String? notes,
  }) {
    return TransferModel(
      id: id,
      caseId: caseId,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      fromUserRole: fromUserRole,
      toUserId: toUserId,
      toUserName: toUserName,
      toUserRole: toUserRole,
      type: type,
      givenAt: givenAt,
      returnedAt: returnedAt ?? this.returnedAt,
      periodDays: periodDays ?? this.periodDays,
      verified: verified ?? this.verified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      notes: notes ?? this.notes,
    );
  }
}
