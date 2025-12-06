import 'package:dartz/dartz.dart';
import '../../../super_admin_&_khadem_layout/attendance/model/attendance_model.dart';

abstract class IAttendanceRepository {
  Future<Either<String, AttendanceModel>> fetchAttendance({String? classId});
}
