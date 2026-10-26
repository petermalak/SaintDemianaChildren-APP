import '../../authentication/model/user_model.dart';
import '../../../core/utils/role_helper.dart';

/// Pope Athanasius meeting (لقاء البابا أثناسيوس) helpers.
///
/// Note: the class UUID can differ between environments (dev/staging/prod),
/// so **prefer resolving by class name** when possible.
const String kLegacyPopeAthanasiusClassId =
    'c08d0a2d-595d-452a-83f0-50c8a67bd90e';

/// Attendance on this day and after stays in the active book.
final DateTime kAttendanceSeasonStart = DateTime(2026, 10, 7);

/// Super admins and khadem who serve Pope Athanasius can see its data.
bool canViewPopeAthanasiusData(UserModel? user) {
  if (user == null) return false;
  if (user.role == UserRole.superAdmin) return true;
  return RoleHelper.getKhademClasses(user).any(
    (info) =>
        isPopeAthanasiusClassName(info.className) ||
        isPopeAthanasiusClassName(info.classDescription),
  );
}

bool isPopeAthanasiusClassName(String? name) {
  if (name == null) return false;
  final n = name.trim().toLowerCase();
  if (n.isEmpty) return false;

  // English spellings
  if (n.contains('athanasius') || n.contains('athnasius')) return true;

  // Arabic variants
  if (n.contains('أثناسيوس') || n.contains('اثناسيوس')) return true;

  return false;
}
