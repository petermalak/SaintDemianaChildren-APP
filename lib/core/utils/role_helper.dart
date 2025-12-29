import '../../features/authentication/model/user_model.dart';

/// Helper class to determine user roles and class memberships
class RoleHelper {
  /// Get all roles a user has across all their class memberships
  static Set<UserRole> getUserRoles(UserModel? user) {
    if (user == null) return {};
    
    final roles = <UserRole>{};
    
    // Add primary role if exists
    if (user.role != null) {
      roles.add(user.role!);
    }
    
    // Check class memberships for roles
    for (final classInfo in user.classes) {
      if (classInfo.membershipRole != null && classInfo.isActive == true) {
        final role = _parseRoleFromString(classInfo.membershipRole!);
        if (role != null) {
          roles.add(role);
        }
      }
    }
    
    return roles;
  }
  
  /// Check if user has a specific role in any class
  static bool hasRole(UserModel? user, UserRole role) {
    return getUserRoles(user).contains(role);
  }
  
  /// Check if user has multiple roles (mixed roles)
  static bool hasMixedRoles(UserModel? user) {
    final roles = getUserRoles(user);
    return roles.length > 1;
  }
  
  /// Get all classes where user has a specific role
  static List<UserClassInfo> getClassesByRole(UserModel? user, UserRole role) {
    if (user == null) return [];
    
    final roleString = _roleToString(role);
    return user.classes
        .where((info) => 
            info.membershipRole == roleString && 
            (info.isActive == true))
        .toList();
  }
  
  /// Get all classes where user is khadem
  static List<UserClassInfo> getKhademClasses(UserModel? user) {
    return getClassesByRole(user, UserRole.khadem);
  }
  
  /// Get all classes where user is makhdoum
  static List<UserClassInfo> getMakhdoumClasses(UserModel? user) {
    return getClassesByRole(user, UserRole.makhdoum);
  }
  
  /// Get the primary role to use for routing (prefers khadem over makhdoum)
  static UserRole? getPrimaryRole(UserModel? user) {
    if (user == null) return null;
    
    final roles = getUserRoles(user);
    
    // Priority: superAdmin > khadem > makhdoum
    if (roles.contains(UserRole.superAdmin)) {
      return UserRole.superAdmin;
    }
    if (roles.contains(UserRole.khadem)) {
      return UserRole.khadem;
    }
    if (roles.contains(UserRole.makhdoum)) {
      return UserRole.makhdoum;
    }
    
    return user.role;
  }
  
  /// Check if user can access khadem features
  static bool canAccessKhademFeatures(UserModel? user) {
    return hasRole(user, UserRole.khadem) || hasRole(user, UserRole.superAdmin);
  }
  
  /// Check if user can access makhdoum features
  static bool canAccessMakhdoumFeatures(UserModel? user) {
    return hasRole(user, UserRole.makhdoum);
  }
  
  /// Get role for a specific class
  static UserRole? getRoleForClass(UserModel? user, String classId) {
    if (user == null) return null;
    
    final classInfo = user.classes.firstWhere(
      (info) => info.classId == classId && (info.isActive == true),
      orElse: () => const UserClassInfo(classId: ''),
    );
    
    if (classInfo.classId.isEmpty) return null;
    
    return _parseRoleFromString(classInfo.membershipRole ?? '');
  }
  
  static UserRole? _parseRoleFromString(String roleString) {
    switch (roleString.toLowerCase()) {
      case 'khadem':
        return UserRole.khadem;
      case 'makhdoum':
        return UserRole.makhdoum;
      case 'admin':
      case 'super_admin':
        return UserRole.superAdmin;
      default:
        return null;
    }
  }
  
  static String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.khadem:
        return 'khadem';
      case UserRole.makhdoum:
        return 'makhdoum';
      case UserRole.superAdmin:
        return 'admin';
    }
  }
}

/// Model to represent a role/class selection
class RoleClassSelection {
  final UserRole role;
  final String? classId;
  final String? className;
  
  const RoleClassSelection({
    required this.role,
    this.classId,
    this.className,
  });
  
  String get displayName {
    final roleName = role == UserRole.khadem ? 'خادم' : 'مخدوم';
    if (className != null && className!.isNotEmpty) {
      return '$roleName - $className';
    }
    return roleName;
  }
}

