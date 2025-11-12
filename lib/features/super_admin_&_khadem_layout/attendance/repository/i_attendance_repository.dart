import 'package:dartz/dartz.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';

import '../model/attendance_model.dart';

abstract class IAttendanceRepository {
  Future<Either<String, AttendanceModel>> fetchAttendance({
    String? classId,
    String? khademId,
    String? khademName,
    String? khademScope,
  });

  Future<Either<String, Unit>> bulkAddAttendance(
      {required List<UserModel> members,
      required String event,
      required DateTime date,
      String? notes,
      bool addScore = true});

  Future<Either<String, Unit>> bulkUpdateAttendance(
      {required List<String> attendanceIds,
      String? event,
      DateTime? date,
      String? notes,
      bool? impactScore,
      bool? shouldAddScore});

  Future<Either<String, Unit>> bulkDeleteAttendance(
      {required List<String> attendanceIds, bool impactScore});
}
