import 'package:equatable/equatable.dart';

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
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    // Try to extract classId from multiple possible sources
    String? extractedClassId = json['classId'];

    // If not found, try from classes array
    if (extractedClassId == null &&
        json['classes'] != null &&
        json['classes'] is List) {
      final classes = json['classes'] as List;
      if (classes.isNotEmpty && classes[0] != null) {
        extractedClassId = classes[0]['classId'];
      }
    }

    // If still not found, try from classMemberships array (JWT token format)
    if (extractedClassId == null &&
        json['classMemberships'] != null &&
        json['classMemberships'] is List) {
      final memberships = json['classMemberships'] as List;

      // For khadems, prioritize their khadem class membership
      final userRole = json['role'];
      if (userRole == 'khadem') {
        // Find the first khadem membership
        final khademMembership = memberships.firstWhere(
          (m) => m != null && m['role'] == 'khadem',
          orElse: () => memberships.isNotEmpty ? memberships[0] : null,
        );
        if (khademMembership != null) {
          extractedClassId = khademMembership['classId'];
        }
      } else if (memberships.isNotEmpty && memberships[0] != null) {
        extractedClassId = memberships[0]['classId'];
      }
    }

    print('🔍 [UserModel] Extracted classId: $extractedClassId from JSON');
    print('🔍 [UserModel] classMemberships: ${json['classMemberships']}');

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
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
    };
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
      ];
}
