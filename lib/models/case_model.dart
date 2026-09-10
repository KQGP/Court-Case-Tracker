import 'package:cloud_firestore/cloud_firestore.dart';

class CaseModel {
  final String id;
  final String caseNumber;
  final String year;
  final String category; // 'civil', 'criminal', 'personnel', 'commercial', 'other'

  final String caseSummary;

  final String partyOneName;
  final List<String> partyOnePersons;
  final String partyTwoName;
  final List<String> partyTwoPersons;

  final String status;
  final String currentHolder;
  final String currentHolderType;
  final String currentHolderName;

  final String assignedJudgeId;
  final String assignedJudgeName;
  final String assignedClerkId;
  final String assignedClerkName;

  final DateTime? lastSessionDate;
  final DateTime? nextSessionDate;
  final String lastOperation;
  final DateTime? lastOperationDate;
  final String lastOperationBy;

  final String location;
  final DateTime createdAt;
  final String createdBy;

  CaseModel({
    required this.id,
    required this.caseNumber,
    required this.year,
    this.category = 'other',
    this.caseSummary = '',
    this.partyOneName = '',
    this.partyOnePersons = const [],
    this.partyTwoName = '',
    this.partyTwoPersons = const [],
    this.status = 'active',
    this.currentHolder = '',
    this.currentHolderType = '',
    this.currentHolderName = '',
    this.assignedJudgeId = '',
    this.assignedJudgeName = '',
    this.assignedClerkId = '',
    this.assignedClerkName = '',
    this.lastSessionDate,
    this.nextSessionDate,
    this.lastOperation = '',
    this.lastOperationDate,
    this.lastOperationBy = '',
    this.location = 'dataCenter',
    DateTime? createdAt,
    this.createdBy = '',
  }) : createdAt = createdAt ?? DateTime.now();

  String get displayName => 'قضية رقم $caseNumber لسنة $year';

  factory CaseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CaseModel(
      id: doc.id,
      caseNumber: data['caseNumber'] ?? '',
      year: data['year'] ?? '',
      category: data['category'] ?? 'other',
      caseSummary: data['caseSummary'] ?? '',
      partyOneName: data['partyOneName'] ?? '',
      partyOnePersons: data['partyOnePersons'] != null ? List<String>.from(data['partyOnePersons']) : [],
      partyTwoName: data['partyTwoName'] ?? '',
      partyTwoPersons: data['partyTwoPersons'] != null ? List<String>.from(data['partyTwoPersons']) : [],
      status: data['status'] ?? 'active',
      currentHolder: data['currentHolder'] ?? '',
      currentHolderType: data['currentHolderType'] ?? '',
      currentHolderName: data['currentHolderName'] ?? '',
      assignedJudgeId: data['assignedJudgeId'] ?? '',
      assignedJudgeName: data['assignedJudgeName'] ?? '',
      assignedClerkId: data['assignedClerkId'] ?? '',
      assignedClerkName: data['assignedClerkName'] ?? '',
      lastSessionDate: (data['lastSessionDate'] as Timestamp?)?.toDate(),
      nextSessionDate: (data['nextSessionDate'] as Timestamp?)?.toDate(),
      lastOperation: data['lastOperation'] ?? '',
      lastOperationDate: (data['lastOperationDate'] as Timestamp?)?.toDate(),
      lastOperationBy: data['lastOperationBy'] ?? '',
      location: data['location'] ?? 'dataCenter',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'caseNumber': caseNumber,
      'year': year,
      'category': category,
      'caseSummary': caseSummary,
      'partyOneName': partyOneName,
      'partyOnePersons': partyOnePersons,
      'partyTwoName': partyTwoName,
      'partyTwoPersons': partyTwoPersons,
      'status': status,
      'currentHolder': currentHolder,
      'currentHolderType': currentHolderType,
      'currentHolderName': currentHolderName,
      'assignedJudgeId': assignedJudgeId,
      'assignedJudgeName': assignedJudgeName,
      'assignedClerkId': assignedClerkId,
      'assignedClerkName': assignedClerkName,
      'lastSessionDate': lastSessionDate != null ? Timestamp.fromDate(lastSessionDate!) : null,
      'nextSessionDate': nextSessionDate != null ? Timestamp.fromDate(nextSessionDate!) : null,
      'lastOperation': lastOperation,
      'lastOperationDate': lastOperationDate != null ? Timestamp.fromDate(lastOperationDate!) : null,
      'lastOperationBy': lastOperationBy,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  CaseModel copyWith({
    String? caseNumber,
    String? year,
    String? category,
    String? caseSummary,
    String? partyOneName,
    List<String>? partyOnePersons,
    String? partyTwoName,
    List<String>? partyTwoPersons,
    String? status,
    String? currentHolder,
    String? currentHolderType,
    String? currentHolderName,
    String? assignedJudgeId,
    String? assignedJudgeName,
    String? assignedClerkId,
    String? assignedClerkName,
    DateTime? lastSessionDate,
    DateTime? nextSessionDate,
    String? lastOperation,
    DateTime? lastOperationDate,
    String? lastOperationBy,
    String? location,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return CaseModel(
      id: id,
      caseNumber: caseNumber ?? this.caseNumber,
      year: year ?? this.year,
      category: category ?? this.category,
      caseSummary: caseSummary ?? this.caseSummary,
      partyOneName: partyOneName ?? this.partyOneName,
      partyOnePersons: partyOnePersons ?? this.partyOnePersons,
      partyTwoName: partyTwoName ?? this.partyTwoName,
      partyTwoPersons: partyTwoPersons ?? this.partyTwoPersons,
      status: status ?? this.status,
      currentHolder: currentHolder ?? this.currentHolder,
      currentHolderType: currentHolderType ?? this.currentHolderType,
      currentHolderName: currentHolderName ?? this.currentHolderName,
      assignedJudgeId: assignedJudgeId ?? this.assignedJudgeId,
      assignedJudgeName: assignedJudgeName ?? this.assignedJudgeName,
      assignedClerkId: assignedClerkId ?? this.assignedClerkId,
      assignedClerkName: assignedClerkName ?? this.assignedClerkName,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      nextSessionDate: nextSessionDate ?? this.nextSessionDate,
      lastOperation: lastOperation ?? this.lastOperation,
      lastOperationDate: lastOperationDate ?? this.lastOperationDate,
      lastOperationBy: lastOperationBy ?? this.lastOperationBy,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
