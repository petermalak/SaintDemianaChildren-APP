
enum UserRole {
  khadem,    // خادم (Servant/Admin)
  makhdoum,  // مخدوم (Congregant/Member)
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String? password;
  final UserRole role;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final String? fathersPhoneNumber;
  final String? mothersPhoneNumber;
  final DateTime? birthdate;
  final String? address;
  final String? addressLocationLink;
  final String? fatherOfConfession;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.password,
    required this.role,
    this.profileImage,
    required this.createdAt,
    this.lastLogin,
    this.fathersPhoneNumber,
    this.mothersPhoneNumber,
    this.birthdate,
    this.address,
    this.addressLocationLink,
    this.fatherOfConfession,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      password: json['password'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${json['role']}',
        orElse: () => UserRole.makhdoum,
      ),
      profileImage: json['profileImage'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      fathersPhoneNumber: json['fathersPhoneNumber'],
      mothersPhoneNumber: json['mothersPhoneNumber'],
      birthdate: json['birthdate'] != null ? DateTime.parse(json['birthdate']) : null,
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
      'role': role.toString().split('.').last,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'fathersPhoneNumber': fathersPhoneNumber,
      'mothersPhoneNumber': mothersPhoneNumber,
      'birthdate': birthdate?.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
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
}