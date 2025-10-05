import '../features/authentication/model/user_model.dart';
import 'class_model.dart';

class ClassMembershipModel {
  final String id;
  final String classId;
  final String userId;
  final UserRole role;
  final DateTime joinedAt;
  final bool isActive;
  final String? assignedBy;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserModel? user;
  final ClassModel? classModel;

  ClassMembershipModel({
    required this.id,
    required this.classId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.isActive,
    this.assignedBy,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.classModel,
  });

  factory ClassMembershipModel.fromJson(Map<String, dynamic> json) {
    return ClassMembershipModel(
      id: json['id'] ?? '',
      classId: json['classId'] ?? '',
      userId: json['userId'] ?? '',
      role: UserModel.parseRole(json['role']),
      joinedAt:
          DateTime.parse(json['joinedAt'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? true,
      assignedBy: json['assignedBy'],
      notes: json['notes'],
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      classModel:
          json['class'] != null ? ClassModel.fromJson(json['class']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classId': classId,
      'userId': userId,
      'role': role.name,
      'joinedAt': joinedAt.toIso8601String(),
      'isActive': isActive,
      'assignedBy': assignedBy,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ClassMembershipModel copyWith({
    String? id,
    String? classId,
    String? userId,
    UserRole? role,
    DateTime? joinedAt,
    bool? isActive,
    String? assignedBy,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserModel? user,
    ClassModel? classModel,
  }) {
    return ClassMembershipModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
      assignedBy: assignedBy ?? this.assignedBy,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
      classModel: classModel ?? this.classModel,
    );
  }

  String get roleDisplayName {
    switch (role) {
      case UserRole.khadem:
        return 'خادم';
      case UserRole.makhdoum:
        return 'مخدوم';
      case UserRole.superAdmin:
        return 'مدير عام';
    }
  }

  @override
  String toString() {
    return 'ClassMembershipModel(id: $id, classId: $classId, userId: $userId, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClassMembershipModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
