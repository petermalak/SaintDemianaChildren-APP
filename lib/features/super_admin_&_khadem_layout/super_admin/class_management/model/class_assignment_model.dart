import 'package:collection/collection.dart';

class AssignmentUser {
  final String id;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? role;

  const AssignmentUser({
    required this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.role,
  });

  factory AssignmentUser.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const AssignmentUser(id: '');
    }
    return AssignmentUser(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      role: json['role'] as String?,
    );
  }
}

class AssignedMakhdoum {
  final String id;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? notes;

  const AssignedMakhdoum({
    required this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.notes,
  });

  factory AssignedMakhdoum.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const AssignedMakhdoum(id: '');
    }
    return AssignedMakhdoum(
      id: json['id']?.toString() ?? json['makhdoumId']?.toString() ?? '',
      name: json['name'] as String? ?? json['makhdoum']?['name'] as String?,
      email: json['email'] as String? ?? json['makhdoum']?['email'] as String?,
      phoneNumber: json['phoneNumber'] as String? ??
          json['makhdoum']?['phoneNumber'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      'makhdoumId': id,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}

class ClassAssignmentsModel {
  final String classId;
  final String className;
  final List<AssignmentUser> khadems;
  final List<AssignmentUser> makhdoums;
  final Map<String, List<AssignedMakhdoum>> groupedAssignments;
  final List<AssignmentUser> unassignedMakhdoums;

  const ClassAssignmentsModel({
    required this.classId,
    required this.className,
    required this.khadems,
    required this.makhdoums,
    required this.groupedAssignments,
    required this.unassignedMakhdoums,
  });

  factory ClassAssignmentsModel.fromJson(Map<String, dynamic> json) {
    final classInfo = json['class'] as Map<String, dynamic>? ?? {};
    final khademList = (json['khadem'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(AssignmentUser.fromJson)
            .where((user) => user.id.isNotEmpty)
            .toList(growable: false) ??
        const <AssignmentUser>[];

    final makhdoumList = (json['makhdoum'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(AssignmentUser.fromJson)
            .where((user) => user.id.isNotEmpty)
            .toList(growable: false) ??
        const <AssignmentUser>[];

    final groupedData = <String, List<AssignedMakhdoum>>{};
    final rawGrouped = json['groupedAssignments'];
    if (rawGrouped is Map<String, dynamic>) {
      rawGrouped.forEach((key, value) {
        final entries = (value as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(AssignedMakhdoum.fromJson)
                .where((assignment) => assignment.id.isNotEmpty)
                .toList() ??
            const <AssignedMakhdoum>[];
        groupedData[key] = entries;
      });
    }

    final unassignedList = (json['unassignedMakhdoum'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(AssignmentUser.fromJson)
            .where((user) => user.id.isNotEmpty)
            .toList(growable: false) ??
        const <AssignmentUser>[];

    return ClassAssignmentsModel(
      classId: classInfo['id']?.toString() ?? '',
      className: classInfo['name']?.toString() ?? '',
      khadems: khademList,
      makhdoums: makhdoumList,
      groupedAssignments: groupedData,
      unassignedMakhdoums: unassignedList,
    );
  }

  static List<Map<String, dynamic>> buildUpdatePayload(
    Map<String, Set<String>> selections, {
    Map<String, Map<String, String?>>? notes,
  }) {
    return selections.entries
        .where((entry) => entry.key.isNotEmpty)
        .map((entry) {
      final khademId = entry.key;
      final selectedMakhdoums = entry.value.toList();
      selectedMakhdoums.sort();

      final khademNotes = notes?[khademId] ?? const {};

      final payloadMakhdoums = selectedMakhdoums
          .map((makhdoumId) => AssignedMakhdoum(
                id: makhdoumId,
                notes: khademNotes[makhdoumId],
              ).toPayload())
          .toList();

      return {
        'khademId': khademId,
        'makhdoums': payloadMakhdoums,
      };
    }).sortedBy<String>((entry) => entry['khademId'] as String);
  }
}
