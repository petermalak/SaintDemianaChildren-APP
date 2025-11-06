import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:saint_demiana_children/core/services/interface/i_api_service.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/attendance/model/attendance_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/attendance/repository/i_attendance_repository.dart';

import '../../../../core/constants/api_endpoints.dart';

class AttendanceRepository implements IAttendanceRepository {
  AttendanceRepository(this._apiService);
  final IApiService _apiService;
  @override
  Future<Either<String, AttendanceModel>> fetchAttendance(
      {String? classId}) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (classId != null && classId.isNotEmpty) {
        queryParameters['classId'] = classId;
      }

      // Fetch all attendance records (removed type filter)
      final response = await _apiService.get(
        path: ApiEndpoints.attendance,
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );

      // Debug: Print the response to see what we're getting
      print('Attendance API Response: ${response.data}');
      print(
          'Attendance count: ${(response.data is List) ? response.data.length : "unknown"}');

      return right(AttendanceModel.fromJson(response.data));
    } on DioException catch (e) {
      print('DioException in fetchAttendance: ${e.message}');
      print('Response data: ${e.response?.data}');
      return left(_apiService.handleError(e));
    } catch (e) {
      print('Unexpected error in fetchAttendance: $e');
      return left("An unexpected error occurred: $e");
    }
  }

  @override
  Future<Either<String, Unit>> bulkAddAttendance(
      {required List<UserModel> members,
      required String event,
      required DateTime date,
      String? notes}) async {
    try {
      final requestBody = {
        "date":
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
        "type": event,
        "note": notes ?? "",
        "users_ids": members.map((e) => e.id).toList()
      };

      print(
          '🌐 [AttendanceRepository] Calling API: ${ApiEndpoints.bulkAddAttendance}');
      print('🌐 Request body: $requestBody');

      final response = await _apiService.post(
          path: ApiEndpoints.bulkAddAttendance, body: requestBody);

      print('✅ [AttendanceRepository] API call successful');
      print('✅ Response: ${response.data}');

      return right(unit);
    } on DioException catch (e) {
      print('❌ [AttendanceRepository] DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      return left(_apiService.handleError(e));
    } catch (e) {
      print('❌ [AttendanceRepository] Unexpected error: $e');
      return left("An unexpected error occurred: $e");
    }
  }
}
