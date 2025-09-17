import 'dart:convert';

enum UserRole {
  khadem,    // خادم (Servant/Admin)
  makhdoum,  // مخدوم (Congregant/Member)
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? password;
  final UserRole role;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final Map<String, dynamic> additionalData;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.password,
    required this.role,
    this.profileImage,
    required this.createdAt,
    this.lastLogin,
    this.additionalData = const {},
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      password: json['password'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${json['role']}',
        orElse: () => UserRole.makhdoum,
      ),
      profileImage: json['profileImage'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      additionalData: json['additionalData'] is String 
          ? json['additionalData'].isNotEmpty 
              ? _parseAdditionalData(json['additionalData']) 
              : {} 
          : json['additionalData'] ?? {},
    );
  }

  // Helper method to safely parse additionalData JSON string
  static Map<String, dynamic> _parseAdditionalData(String jsonString) {
    try {
      final Map<dynamic, dynamic> decoded = jsonDecode(jsonString);
      // Convert to Map<String, dynamic> to ensure type safety
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    } catch (e) {
      // Use logging service if available, otherwise silently handle the error
      // We don't import the logging service here to avoid circular dependencies
      return {};
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role.toString().split('.').last,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'additionalData': additionalData,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? password,
    UserRole? role,
    String? profileImage,
    DateTime? createdAt,
    DateTime? lastLogin,
    Map<String, dynamic>? additionalData,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}