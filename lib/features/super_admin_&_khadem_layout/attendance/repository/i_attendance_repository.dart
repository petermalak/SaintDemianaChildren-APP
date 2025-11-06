import 'package:dartz/dartz.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';

import '../model/attendance_model.dart';

abstract class IAttendanceRepository {
  Future<Either<String, AttendanceModel>> fetchAttendance({String? classId});

  Future<Either<String, Unit>> bulkAddAttendance(
      {required List<UserModel> members,
      required String event,
      required DateTime date,
      String? notes});
}
