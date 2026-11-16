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

  /// One row per active membership, plus a general-admin row when that is the account role.
  static List<RoleClassSelection> membershipContexts(UserModel? user) {
    if (user == null) return const [];
    final contexts = <RoleClassSelection>[];
    if (user.role == UserRole.superAdmin) {
      contexts.add(const RoleClassSelection(role: UserRole.superAdmin));
    }
    for (final info in getKhademClasses(user)) {
      contexts.add(RoleClassSelection(
        role: UserRole.khadem,
        classId: info.classId,
        className: info.className,
      ));
    }
    for (final info in getMakhdoumClasses(user)) {
      contexts.add(RoleClassSelection(
        role: UserRole.makhdoum,
        classId: info.classId,
        className: info.className,
      ));
    }
    for (final program in user.programs) {
      for (final role in programRoles(program)) {
        contexts.add(RoleClassSelection(
          role: role == 'makhdoum' ? UserRole.makhdoum : UserRole.khadem,
          className: program.name,
          programId: program.id,
          programRole: role,
        ));
      }
    }
    return contexts;
  }

  /// The highest program role. It includes every role below it in the Taio table.
  static List<String> programRoles(ProgramMembership program) {
    if (program.scope == 'all' || program.roles.contains('amin')) return const ['amin'];
    if (program.scope == 'class' || program.roles.contains('class_servant')) return const ['class'];
    if (program.scope == 'score' || program.roles.contains('score_servant')) return const ['score'];
    return const ['makhdoum'];
  }

  static ProgramMembership? programFor(UserModel? user, RoleClassSelection? session) {
    final programId = session?.programId;
    if (user == null || programId == null) return null;
    for (final program in user.programs) {
      if (program.id == programId) return program;
    }
    return null;
  }

  static String legacyHomePath(UserModel? user) {
    final contexts = membershipContexts(user);
    final onlyMakhdoum = contexts.isNotEmpty &&
        contexts.every((selection) => selection.role == UserRole.makhdoum);
    return onlyMakhdoum ? '/makhdoum' : '/khadem';
  }

  static Set<String> classIdsFor(UserModel? user, UserRole role) {
    final source = role == UserRole.makhdoum
        ? getMakhdoumClasses(user)
        : getKhademClasses(user);
    return source
        .map((info) => info.classId)
        .where((id) => id.isNotEmpty)
        .toSet();
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
  final String? programId;
  final String? programRole;
  
  const RoleClassSelection({
    required this.role,
    this.classId,
    this.className,
    this.programId,
    this.programRole,
  });
  
  String get displayName {
    if (programId != null) {
      final roleName = programRoleTitle(programRole);
      final name = className?.trim();
      return name == null || name.isEmpty ? roleName : '$roleName — $name';
    }
    final roleName = switch (role) {
      UserRole.khadem => 'خادم',
      UserRole.makhdoum => 'مخدوم',
      UserRole.superAdmin => 'مدير عام',
    };
    if (className != null && className!.trim().isNotEmpty) {
      return '$roleName — $className';
    }
    return roleName;
  }

  /// Short boundary for this row, using the Taio role table.
  String get detail {
    if (programId != null) {
      return switch (programRole) {
        'amin' => 'كل الفصول، اعتماد السحب، الميزانية والأحداث. يشمل خادم الفصل وخادم السكور والمخدوم.',
        'class' => 'حضور فصله وأولاده والافتقاد. يشمل بنود السكور وحساب المخدوم. يعفي مخدوم من شرط 25% لحجز الرحلة. من غير ميزانية.',
        'score' => 'بنود التقييم لكل الفصول: المبادرة والخلوة والمسابقات. يشمل حساب المخدوم. لا يسجّل حضور الفصل.',
        _ => 'رصيده وسجله ورمزه وطلب السحب. لا يرى الترتيب ولا يسجّل نقاط غيره.',
      };
    }
    return switch (role) {
      UserRole.superAdmin => 'إدارة الكنيسة. هذا ليس أمين الخدمة.',
      UserRole.khadem => 'خادم هذا الفصل في الكنيسة، خارج طايو.',
      UserRole.makhdoum => 'مخدوم هذا الفصل في الكنيسة، خارج طايو.',
    };
  }

  static String programRoleTitle(String? role) {
    return switch (role) {
      'amin' => 'أمين الخدمة',
      'class' => 'خادم الفصل',
      'score' => 'خادم السكور',
      _ => 'مخدوم',
    };
  }

  bool sameAs(RoleClassSelection other) {
    return role == other.role &&
        classId == other.classId &&
        programId == other.programId &&
        programRole == other.programRole;
  }
}

