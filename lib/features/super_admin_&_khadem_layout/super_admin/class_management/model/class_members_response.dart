import 'class_membership_model.dart';

/// Response from GET /classes/:id/members
class ClassMembersResponse {
  final String classId;
  final String className;
  final String? classDescription;
  final List<ClassMembershipModel> memberships;
  final int totalMembers;

  ClassMembersResponse({
    required this.classId,
    required this.className,
    this.classDescription,
    required this.memberships,
    this.totalMembers = 0,
  });

  factory ClassMembersResponse.fromJson(Map<String, dynamic> json) {
    final classData = json['class'];
    final classId = classData != null && classData['id'] != null
        ? classData['id'].toString()
        : '';
    final className = classData != null && classData['name'] != null
        ? classData['name'].toString()
        : '';
    final classDescription = classData != null && classData['description'] != null
        ? classData['description'].toString()
        : null;

    final rawList = json['memberships'];
    final List<ClassMembershipModel> memberships = rawList is List
        ? (rawList as List)
            .whereType<Map<String, dynamic>>()
            .map(ClassMembershipModel.fromJson)
            .toList()
        : [];

    final totalMembers = json['totalMembers'] is int
        ? json['totalMembers'] as int
        : memberships.length;

    return ClassMembersResponse(
      classId: classId,
      className: className,
      classDescription: classDescription,
      memberships: memberships,
      totalMembers: totalMembers,
    );
  }
}
