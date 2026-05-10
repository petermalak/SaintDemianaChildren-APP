import 'package:equatable/equatable.dart';
import 'dart:convert';

enum UserRole {
  khadem, // خادم (Servant/Admin)
  makhdoum, // مخدوم (Congregant/Member)
  superAdmin, // مدير عام (Super Administrator)
}

class UserModel extends Equatable {
  final String? id;
  String? name;
  String? email;
  String? token;
  String? phoneNumber;
  String? password;
  UserRole? role;
  String? profileImage;
  DateTime? createdAt;
  DateTime? lastLogin;
  String? fathersPhoneNumber;
  String? mothersPhoneNumber;
  DateTime? birthdate;
  String? address;
  String? addressLocationLink;
  String? fatherOfConfession;
  String? classId;
  final List<UserClassInfo> classes;
  final List<UserClassAssignment> classAssignments;
  bool? isPopeAthnasius;
  PopeAthnasiusMeetingData? popeAthnasiusMeetingData;
  List<String>?
      classIds; // Temporary field for class assignment during creation
  UserModel({
    this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.password,
    this.role,
    this.profileImage,
    this.classId,
    this.createdAt,
    this.lastLogin,
    this.fathersPhoneNumber,
    this.mothersPhoneNumber,
    this.birthdate,
    this.token,
    this.address,
    this.addressLocationLink,
    this.fatherOfConfession,
    List<UserClassInfo>? classes,
    List<UserClassAssignment>? classAssignments,
    this.isPopeAthnasius,
    this.popeAthnasiusMeetingData,
    this.classIds,
  })  : classes = classes ?? const [],
        classAssignments = classAssignments ?? const [];

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    final List<UserClassInfo> parsedClasses = (json['classes'] is List)
        ? (json['classes'] as List)
            .whereType<Map<String, dynamic>>()
            .map(UserClassInfo.fromJson)
            .toList()
        : <UserClassInfo>[];

    // Try to extract classId from multiple possible sources
    String? extractedClassId = json['classId'];

    if (extractedClassId == null && parsedClasses.isNotEmpty) {
      extractedClassId = parsedClasses.first.classId;
    }

    List<Map<String, dynamic>> memberships = [];
    if (json['classMemberships'] != null) {
      if (json['classMemberships'] is List) {
        memberships = (json['classMemberships'] as List)
            .whereType<Map<String, dynamic>>()
            .toList();
      } else if (json['classMemberships'] is Map) {
        // Handle case where classMemberships comes as a Map instead of List
        // This can happen with certain JSON serialization issues
        print('⚠️ [UserModel] classMemberships is a Map, converting to List');
        try {
          final map = json['classMemberships'] as Map<String, dynamic>;
          // Try to extract values if it's a map of objects
          if (map.isNotEmpty) {
            final values =
                map.values.whereType<Map<String, dynamic>>().toList();
            memberships = values;
          }
        } catch (e) {
          print(
              '❌ [UserModel] Error converting classMemberships Map to List: $e');
          memberships = [];
        }
      } else {
        // Not a List or Map - log and use empty list
        print(
            '⚠️ [UserModel] classMemberships is neither List nor Map, type: ${json['classMemberships'].runtimeType}');
        memberships = [];
      }
    }

    if (extractedClassId == null && memberships.isNotEmpty) {
      final userRole = json['role'];
      if (userRole == 'khadem') {
        final khademMembership = memberships.firstWhere(
          (m) => m['role'] == 'khadem',
          orElse: () => memberships.first,
        );
        extractedClassId = khademMembership['classId'];
      } else {
        extractedClassId = memberships.first['classId'];
      }
    }

    final List<UserClassInfo> combinedClasses = parsedClasses.isNotEmpty
        ? parsedClasses
        : memberships
            .map(UserClassInfo.fromMembershipJson)
            .where((info) => info.classId.isNotEmpty)
            .toList();

    if (extractedClassId == null && combinedClasses.isNotEmpty) {
      extractedClassId = combinedClasses.first.classId;
    }

    final List<UserClassAssignment> parsedAssignments =
        (json['classAssignments'] is List)
            ? (json['classAssignments'] as List)
                .whereType<Map<String, dynamic>>()
                .map(UserClassAssignment.fromJson)
                .toList()
            : const <UserClassAssignment>[];

    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      token: token,
      classId: extractedClassId,
      phoneNumber: json['phoneNumber'],
      password: json['password'],
      role: parseRole(json['role']),
      profileImage: json['profileImage'],
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastLogin:
          json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      fathersPhoneNumber: json['fathersPhoneNumber'],
      mothersPhoneNumber: json['mothersPhoneNumber'],
      birthdate:
          json['birthdate'] != null ? DateTime.parse(json['birthdate']) : null,
      address: json['address'],
      addressLocationLink: json['addressLocationLink'],
      fatherOfConfession: json['fatherOfConfession'],
      classes: combinedClasses,
      classAssignments: parsedAssignments,
      isPopeAthnasius: json['isPopeAthnasius'] as bool? ?? false,
      popeAthnasiusMeetingData: json['popeAthnasiusMeetingData'] != null
          ? PopeAthnasiusMeetingData.fromJson(
              json['popeAthnasiusMeetingData'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'name': name,
      'email': email,
      'token': token, // Save token for persistence
      'classId': classId, // Save class ID
      'phoneNumber': phoneNumber,
      'password': password,
      'role': _roleToString(role),
      'profileImage': profileImage,
      'createdAt': createdAt?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'fathersPhoneNumber': fathersPhoneNumber,
      'mothersPhoneNumber': mothersPhoneNumber,
      'birthdate':
          birthdate?.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
      'address': address,
      'addressLocationLink': addressLocationLink,
      'fatherOfConfession': fatherOfConfession,
      'classes': classes.map((c) => c.toJson()).toList(),
      'isPopeAthnasius': isPopeAthnasius ?? false,
    };

    // Include Pope Athanasius meeting data if provided
    if (popeAthnasiusMeetingData != null) {
      final meetingDataJson = popeAthnasiusMeetingData!.toJson();
      // Extract classPhase from additionalData if present
      int? classPhase;
      if (meetingDataJson['additionalData'] != null) {
        final additionalData =
            meetingDataJson['additionalData'] as Map<String, dynamic>?;
        if (additionalData != null &&
            additionalData.containsKey('classPhase')) {
          classPhase = additionalData['classPhase'] as int?;
          // Remove classPhase from additionalData as it's stored separately
          final updatedAdditionalData =
              Map<String, dynamic>.from(additionalData);
          updatedAdditionalData.remove('classPhase');
          meetingDataJson['additionalData'] = updatedAdditionalData;
        }
      }
      json['popeAthnasiusMeetingData'] = meetingDataJson;
      if (classPhase != null) {
        json['classPhase'] = classPhase;
      }
    }

    // Include classIds only if provided (for user creation)
    if (classIds != null && classIds!.isNotEmpty) {
      json['classIds'] = classIds;
    }

    return json;
  }

  static String? _roleToString(UserRole? role) {
    if (role == null) return null;

    switch (role) {
      case UserRole.khadem:
        return 'khadem';
      case UserRole.makhdoum:
        return 'makhdoum';
      case UserRole.superAdmin:
        return 'admin';
    }
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? token,
    String? classId,
    String? phoneNumber,
    String? password,
    UserRole? role,
    String? profileImage,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? fathersPhoneNumber,
    String? mothersPhoneNumber,
    DateTime? birthdate,
    String? address,
    String? addressLocationLink,
    String? fatherOfConfession,
    List<UserClassInfo>? classes,
    List<UserClassAssignment>? classAssignments,
    bool? isPopeAthnasius,
    PopeAthnasiusMeetingData? popeAthnasiusMeetingData,
    List<String>? classIds,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      token: token ?? this.token,
      classId: classId ?? this.classId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      password: password ?? this.password,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      fathersPhoneNumber: fathersPhoneNumber ?? this.fathersPhoneNumber,
      mothersPhoneNumber: mothersPhoneNumber ?? this.mothersPhoneNumber,
      birthdate: birthdate ?? this.birthdate,
      address: address ?? this.address,
      addressLocationLink: addressLocationLink ?? this.addressLocationLink,
      fatherOfConfession: fatherOfConfession ?? this.fatherOfConfession,
      classes: classes ?? this.classes,
      classAssignments: classAssignments ?? this.classAssignments,
      isPopeAthnasius: isPopeAthnasius ?? this.isPopeAthnasius,
      popeAthnasiusMeetingData:
          popeAthnasiusMeetingData ?? this.popeAthnasiusMeetingData,
      classIds: classIds ?? this.classIds,
    );
  }

  String get roleDisplayName {
    switch (role!) {
      case UserRole.khadem:
        return 'خادم';
      case UserRole.makhdoum:
        return 'مخدوم';
      case UserRole.superAdmin:
        return 'مدير عام';
    }
  }

  static UserRole parseRole(String? roleString) {
    if (roleString == null) return UserRole.makhdoum;

    switch (roleString) {
      case 'khadem':
        return UserRole.khadem;
      case 'makhdoum':
        return UserRole.makhdoum;
      case 'admin':
      case 'super_admin': // Keep for backwards compatibility
        return UserRole.superAdmin;
      default:
        return UserRole.makhdoum;
    }
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        token,
        classId,
        phoneNumber,
        password,
        role,
        profileImage,
        createdAt,
        lastLogin,
        fathersPhoneNumber,
        mothersPhoneNumber,
        birthdate,
        address,
        addressLocationLink,
        fatherOfConfession,
        classes,
        classAssignments,
        isPopeAthnasius,
        popeAthnasiusMeetingData,
      ];

  String? get primaryClassId {
    if (classId != null && classId!.isNotEmpty) {
      return classId;
    }
    if (classes.isNotEmpty) {
      return classes.first.classId;
    }
    return null;
  }

  List<UserClassSummary> get classSummaries {
    if (classes.isEmpty && classAssignments.isEmpty) {
      return const [];
    }

    final membershipMap = {
      for (final membership in classes) membership.classId: membership
    };

    final assignmentMap = {
      for (final assignment in classAssignments) assignment.classId: assignment
    };

    final classIds = <String>{
      ...membershipMap.keys,
      ...assignmentMap.keys,
    };

    return classIds.map((id) {
      final membership = membershipMap[id];
      final assignment = assignmentMap[id];
      return UserClassSummary(
        classId: id,
        className: assignment?.className ?? membership?.className,
        membershipRole: membership?.membershipRole,
        isActive: membership?.isActive ?? true,
        joinedAt: membership?.joinedAt,
        assignedKhadems: assignment?.khadems ?? const [],
      );
    }).toList();
  }
}

class UserClassInfo extends Equatable {
  final String classId;
  final String? className;
  final String? classDescription;
  final String? membershipRole;
  final bool? isActive;
  final DateTime? joinedAt;

  const UserClassInfo({
    required this.classId,
    this.className,
    this.classDescription,
    this.membershipRole,
    this.isActive,
    this.joinedAt,
  });

  factory UserClassInfo.fromJson(Map<String, dynamic> json) {
    return UserClassInfo(
      classId: (json['classId'] ?? '').toString(),
      className: json['className'] as String?,
      classDescription: json['classDescription'] as String?,
      membershipRole: json['membershipRole'] as String?,
      isActive: json['isActive'] is bool ? json['isActive'] as bool : null,
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'].toString())
          : null,
    );
  }

  factory UserClassInfo.fromMembershipJson(Map<String, dynamic> json) {
    final classData = json['class'] is Map<String, dynamic>
        ? json['class'] as Map<String, dynamic>
        : null;

    return UserClassInfo(
      classId: (json['classId'] ?? '').toString(),
      className: classData != null ? classData['name'] as String? : null,
      classDescription:
          classData != null ? classData['description'] as String? : null,
      membershipRole: json['role'] as String?,
      isActive: json['isActive'] is bool ? json['isActive'] as bool : null,
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'classId': classId,
      'className': className,
      'classDescription': classDescription,
      'membershipRole': membershipRole,
      'isActive': isActive,
      'joinedAt': joinedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        classId,
        className,
        classDescription,
        membershipRole,
        isActive,
        joinedAt,
      ];
}

class UserClassAssignment extends Equatable {
  final String classId;
  final String? className;
  final List<AssignmentKhademInfo> khadems;

  const UserClassAssignment({
    required this.classId,
    this.className,
    List<AssignmentKhademInfo>? khadems,
  }) : khadems = khadems ?? const [];

  factory UserClassAssignment.fromJson(Map<String, dynamic> json) {
    final khademEntries = (json['khadems'] is List)
        ? (json['khadems'] as List)
            .whereType<Map<String, dynamic>>()
            .map(AssignmentKhademInfo.fromJson)
            .toList()
        : const <AssignmentKhademInfo>[];

    return UserClassAssignment(
      classId: (json['classId'] ?? '').toString(),
      className: json['className'] as String?,
      khadems: khademEntries,
    );
  }

  @override
  List<Object?> get props => [classId, className, khadems];
}

class AssignmentKhademInfo extends Equatable {
  final String? id;
  final String? name;
  final String? phoneNumber;
  final String? email;

  const AssignmentKhademInfo({
    this.id,
    this.name,
    this.phoneNumber,
    this.email,
  });

  factory AssignmentKhademInfo.fromJson(Map<String, dynamic> json) {
    return AssignmentKhademInfo(
      id: json['id']?.toString(),
      name: json['name'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, phoneNumber, email];
}

class UserClassSummary extends Equatable {
  final String classId;
  final String? className;
  final String? membershipRole;
  final bool isActive;
  final DateTime? joinedAt;
  final List<AssignmentKhademInfo> assignedKhadems;

  const UserClassSummary({
    required this.classId,
    this.className,
    this.membershipRole,
    this.isActive = true,
    this.joinedAt,
    List<AssignmentKhademInfo>? assignedKhadems,
  }) : assignedKhadems = assignedKhadems ?? const [];

  String get khademNames {
    if (assignedKhadems.isEmpty) {
      return 'لا يوجد خدام محددين';
    }
    return assignedKhadems
        .map((khadem) => khadem.name ?? 'خادم بدون اسم')
        .join('، ');
  }

  @override
  List<Object?> get props => [
        classId,
        className,
        membershipRole,
        isActive,
        joinedAt,
        assignedKhadems,
      ];
}

class PopeAthnasiusMeetingData extends Equatable {
  final String? id;
  final String? userId;
  final Map<String, dynamic>? additionalData;
  final int? classPhase;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PopeAthnasiusMeetingData({
    this.id,
    this.userId,
    this.additionalData,
    this.classPhase,
    this.createdAt,
    this.updatedAt,
  });

  factory PopeAthnasiusMeetingData.fromJson(Map<String, dynamic> json) {
    int? classPhase;
    if (json['classPhase'] != null) {
      final v = json['classPhase'];
      if (v is int) {
        classPhase = v;
      } else if (v is num) {
        classPhase = v.toInt();
      } else {
        classPhase = int.tryParse(v.toString());
      }
    }
    Map<String, dynamic>? additionalData;
    final raw = json['additionalData'];
    if (raw != null) {
      if (raw is Map<String, dynamic>) {
        additionalData = raw;
      } else if (raw is Map) {
        additionalData = Map<String, dynamic>.from(raw);
      } else if (raw is String) {
        // Some backends/DB drivers may serialize JSON as a string.
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            additionalData = decoded;
          } else if (decoded is Map) {
            additionalData = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {
          // If parsing fails, leave additionalData as null
        }
      }
    }
    return PopeAthnasiusMeetingData(
      id: json['id']?.toString(),
      userId: json['userId']?.toString(),
      additionalData: additionalData,
      classPhase: classPhase,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'additionalData': additionalData,
      'classPhase': classPhase,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// All Pope Athanasius fields merged for export (additionalData + classPhase).
  Map<String, dynamic> get exportMap {
    final map = Map<String, dynamic>.from(additionalData ?? {});
    if (classPhase != null) map['classPhase'] = classPhase;
    return map;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        additionalData,
        classPhase,
        createdAt,
        updatedAt,
      ];
}
