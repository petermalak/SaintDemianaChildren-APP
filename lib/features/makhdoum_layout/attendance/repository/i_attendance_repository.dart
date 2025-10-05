import 'package:dartz/dartz.dart';

abstract class IAttendanceRepository {
  Future<Either<String, List>> fetchAttendance();
}
