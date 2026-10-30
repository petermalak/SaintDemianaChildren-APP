import 'package:flutter/foundation.dart';

import '../../features/authentication/model/user_model.dart';
import '../utils/role_helper.dart';

/// The membership (role + class) chosen for this login session.
class SessionContext extends ChangeNotifier {
  SessionContext._();

  static final SessionContext instance = SessionContext._();

  RoleClassSelection? current;

  void select(RoleClassSelection value) {
    final previous = current;
    if (previous != null && previous.sameAs(value)) return;
    current = value;
    notifyListeners();
  }

  void clear() {
    if (current == null) return;
    current = null;
    notifyListeners();
  }

  /// Super-admin shell, not a class membership the person chose to serve in.
  static bool isSuperAdminContext(UserModel? user) {
    final session = instance.current;
    if (session != null) return session.role == UserRole.superAdmin;
    return user?.role == UserRole.superAdmin;
  }

  /// Servant context for one class. Does not treat a global khadem cache as enough
  /// when a membership was already chosen.
  static bool isKhademContext(UserModel? user) {
    final session = instance.current;
    if (session != null) return session.role == UserRole.khadem;
    return user?.role == UserRole.khadem;
  }
}

/// Keeps class lists to the memberships of [role], unless this is the admin shell.
List<T> classesForContext<T>({
  required UserModel? user,
  required UserRole role,
  required List<T> classes,
  required String Function(T item) idOf,
}) {
  if (role != UserRole.makhdoum && SessionContext.isSuperAdminContext(user)) {
    return classes;
  }
  final ids = RoleHelper.classIdsFor(user, role);
  if (ids.isEmpty) return classes;
  return classes.where((item) => ids.contains(idOf(item))).toList();
}
