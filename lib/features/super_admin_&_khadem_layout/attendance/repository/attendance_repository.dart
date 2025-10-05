import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:saint_demiana_children/core/services/interface/i_api_service.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/attendance/model/attendance_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/attendance/repository/i_attendance_repository.dart';


class AttendanceRepository implements IAttendanceRepository {
  AttendanceRepository(this._apiService);
  final IApiService _apiService;
  @override
  Future<Either<String, AttendanceModel>> fetchAttendance() async {
    try {
      // final response = await _apiService.get(path: ApiEndpoints.attendance);
      // return right(AttendanceModel.fromJson(response.data));
      return right(const AttendanceModel(attendance: {
        "John Doe": {
          "12-10-2025": {"tsb7a": true, "odas": true}
        },
        "Jane Smith": {
          "5-10-2025": {"general": true, "private": true}
        }
      }, attendanceDates: [
        "12-10-2025",
        "5-10-2025"
      ]));
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left("An unexpected error occurred");
    }
  }
}
