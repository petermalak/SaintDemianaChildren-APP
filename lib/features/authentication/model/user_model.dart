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
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ,
      token: token,
      classId: json['classId'] ??
          (json['classes'] != null &&
           json['classes'] is List &&
           (json['classes'] as List).isNotEmpty &&
           json['classes'][0] != null
              ? json['classes'][0]['classId']
              : null),
      phoneNumber: json['phoneNumber'] ,
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
      'phoneNumber': phoneNumber,
      'password': password,
      'role': role?.name,
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

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
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
      case 'super_admin':
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
