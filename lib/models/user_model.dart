import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String role; // 'admin', 'clerk', 'judge'
  final String department;
  final bool active;
  final Map<String, bool> permissions;
  final DateTime createdAt;
  final String createdBy;

  UserModel({
    required this.id,
    required this.name,
    required this.role,
    this.department = '',
    this.active = true,
    Map<String, bool>? permissions,
    DateTime? createdAt,
    this.createdBy = '',
  })  : permissions = permissions ?? _defaultPermissions(role),
        createdAt = createdAt ?? DateTime.now();

  static Map<String, bool> _defaultPermissions(String role) {
    switch (role) {
      case 'admin':
        return {
          'transferFolder': true,
          'editCase': true,
          'changeStatus': true,
          'manageUsers': true,
          'viewDashboard': true,
          'printCase': true,
        };
      case 'judge':
        return {
          'transferFolder': true,
          'editCase': true,
          'changeStatus': true,
          'manageUsers': false,
          'viewDashboard': true,
          'printCase': true,
        };
      case 'clerk':
        return {
          'transferFolder': true,
          'editCase': true,
          'changeStatus': false,
          'manageUsers': false,
          'viewDashboard': true,
          'printCase': true,
        };
      default:
        return {};
    }
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      role: data['role'] ?? 'clerk',
      department: data['department'] ?? '',
      active: data['active'] ?? true,
      permissions: Map<String, bool>.from(data['permissions'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'role': role,
      'department': department,
      'active': active,
      'permissions': permissions,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  UserModel copyWith({
    String? name,
    String? role,
    String? department,
    bool? active,
    Map<String, bool>? permissions,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      department: department ?? this.department,
      active: active ?? this.active,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt,
      createdBy: createdBy,
    );
  }
}
