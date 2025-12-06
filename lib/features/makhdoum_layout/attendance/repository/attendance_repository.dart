import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/interface/i_api_service.dart';
import '../../../super_admin_&_khadem_layout/attendance/model/attendance_model.dart';
import 'i_attendance_repository.dart';

class AttendanceRepository implements IAttendanceRepository {
  final IApiService _apiService;

  AttendanceRepository(this._apiService);

  @override
  Future<Either<String, AttendanceModel>> fetchAttendance({String? classId}) async {
    try {
      // Build query parameters
      final Map<String, dynamic> queryParams = {};
      if (classId != null && classId.isNotEmpty) {
        queryParams['classId'] = classId;
      }

      final response = await _apiService.get(
        path: ApiEndpoints.attendance,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final attendanceModel = AttendanceModel.fromJson(response.data);
        return Right(attendanceModel);
      } else {
        return Left('Failed to fetch attendance: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      return Left(_apiService.handleError(e));
    } catch (e) {
      return Left('Unexpected error: ${e.toString()}');
    }
  }
}
