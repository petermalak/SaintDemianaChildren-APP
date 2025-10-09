import 'dart:convert';
import 'class_membership_model.dart';

class ClassModel {
  final String id;
   String name;
  final String? description;
  final bool isActive;
  final int? maxMembers;
   String? location;
  final Map<String, dynamic>? schedule;
  final String createdBy;
  final String? creatorName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int memberCount;
  final int khademCount;
  final int makhdoumCount;
  final List<ClassMembershipModel>? memberships;

  ClassModel({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    this.maxMembers,
    this.location,
    this.schedule,
    required this.createdBy,
    this.creatorName,
    required this.createdAt,
    required this.updatedAt,
    this.memberCount = 0,
    this.khademCount = 0,
    this.makhdoumCount = 0,
    this.memberships,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? schedule;
    if (json['schedule'] != null) {
      if (json['schedule'] is String) {
        try {
          schedule = Map<String, dynamic>.from(jsonDecode(json['schedule']));
        } catch (e) {
          print('Error parsing schedule JSON: $e');
          schedule = null;
        }
      } else if (json['schedule'] is Map) {
        schedule = Map<String, dynamic>.from(json['schedule']);
      }
    }

    return ClassModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      isActive: json['isActive'] ?? true,
      maxMembers: json['maxMembers'],
      location: json['location'],
      schedule: schedule,
      createdBy: json['createdBy'] ?? '',
      creatorName: json['creator']?['name'],
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      memberCount: json['memberCount'] ?? 0,
      khademCount: json['khademCount'] ?? 0,
      makhdoumCount: json['makhdoumCount'] ?? 0,
      memberships: json['memberships'] != null
          ? (json['memberships'] as List)
              .map((m) => ClassMembershipModel.fromJson(m))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isActive': isActive,
      'maxMembers': maxMembers,
      'location': location,
      'schedule': schedule,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ClassModel copyWith({
    String? id,
    String? name,
    String? description,
    bool? isActive,
    int? maxMembers,
    String? location,
    Map<String, dynamic>? schedule,
    String? createdBy,
    String? creatorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? memberCount,
    int? khademCount,
    int? makhdoumCount,
    List<ClassMembershipModel>? memberships,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      maxMembers: maxMembers ?? this.maxMembers,
      location: location ?? this.location,
      schedule: schedule ?? this.schedule,
      createdBy: createdBy ?? this.createdBy,
      creatorName: creatorName ?? this.creatorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      memberCount: memberCount ?? this.memberCount,
      khademCount: khademCount ?? this.khademCount,
      makhdoumCount: makhdoumCount ?? this.makhdoumCount,
      memberships: memberships ?? this.memberships,
    );
  }

  bool get isAtCapacity {
    if (maxMembers == null) return false;
    return memberCount >= maxMembers!;
  }

  bool get canAddMember {
    if (maxMembers == null) return true;
    return memberCount < maxMembers!;
  }

  String get capacityText {
    if (maxMembers == null) return '$memberCount عضو';
    return '$memberCount / $maxMembers عضو';
  }

  String get scheduleText {
    if (schedule == null) return 'لم يتم تحديد الجدول';

    final days = schedule!['days'] as List<dynamic>?;
    final time = schedule!['time'] as String?;
    final frequency = schedule!['frequency'] as String?;

    String result = '';
    if (days != null && days.isNotEmpty) {
      result += days.join('، ');
    }
    if (time != null) {
      result += ' - $time';
    }
    if (frequency != null) {
      result += ' ($frequency)';
    }

    return result.isEmpty ? 'لم يتم تحديد الجدول' : result;
  }

  @override
  String toString() {
    return 'ClassModel(id: $id, name: $name, memberCount: $memberCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClassModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
