import 'package:dartz/dartz.dart';

import '../model/attendance_model.dart';

abstract class IAttendanceRepository {
  Future<Either<String, AttendanceModel>> fetchAttendance();
}
