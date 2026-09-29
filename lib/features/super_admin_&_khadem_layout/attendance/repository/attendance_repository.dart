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
  Future<Either<String, AttendanceModel>> fetchAttendance({
    String? classId,
    String? khademId,
    String? khademName,
    String? khademScope,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (classId != null && classId.isNotEmpty) {
        queryParameters['classId'] = classId;
      }
      if (khademId != null && khademId.isNotEmpty) {
        queryParameters['khademId'] = khademId;
      }
      if (khademName != null && khademName.isNotEmpty) {
        queryParameters['khademName'] = khademName;
      }
      if (khademScope != null && khademScope.isNotEmpty) {
        queryParameters['khademScope'] = khademScope;
      }

      // Fetch all attendance records (removed type filter)
      final response = await _apiService.get(
        path: ApiEndpoints.attendance,
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );

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
      String? notes,
      bool addScore = true}) async {
    try {
      final requestBody = {
        "date":
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
        "type": event,
        "note": notes ?? "",
        "users_ids": members.map((e) => e.id).toList(),
        "shouldAddScore": addScore
      };

      print(
          '🌐 [AttendanceRepository] Calling API: ${ApiEndpoints.bulkAddAttendance}');
      print('🌐 Request body: $requestBody');

      await _apiService.post(
          path: ApiEndpoints.bulkAddAttendance, body: requestBody);

      print('✅ [AttendanceRepository] API call successful');

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

  @override
  Future<Either<String, Unit>> bulkUpdateAttendance(
      {required List<String> attendanceIds,
      String? event,
      DateTime? date,
      String? notes,
      bool? impactScore,
      bool? shouldAddScore}) async {
    try {
      final requestBody = <String, dynamic>{
        "attendance_ids": attendanceIds,
      };

      if (event != null) {
        requestBody["type"] = event;
      }

      if (date != null) {
        requestBody["date"] =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      }

      if (notes != null) {
        requestBody["notes"] = notes;
      }

      if (impactScore != null) {
        requestBody["impactScore"] = impactScore;
      }

      if (shouldAddScore != null) {
        requestBody["shouldAddScore"] = shouldAddScore;
      }

      print(
          '🌐 [AttendanceRepository] Calling API: ${ApiEndpoints.bulkUpdateAttendance}');
      print('🌐 Request body: $requestBody');

      await _apiService.put(
          path: ApiEndpoints.bulkUpdateAttendance, body: requestBody);

      print('✅ [AttendanceRepository] Bulk update successful');

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

  @override
  Future<Either<String, Unit>> bulkDeleteAttendance(
      {required List<String> attendanceIds, bool impactScore = false}) async {
    try {
      final requestBody = {
        "attendance_ids": attendanceIds,
        "impactScore": impactScore,
      };

      print(
          '🌐 [AttendanceRepository] Calling API: ${ApiEndpoints.bulkDeleteAttendance}');
      print('🌐 Request body: $requestBody');

      // Note: Using POST for bulk delete as DELETE with body is not standard in all HTTP clients
      // The backend route handles this as DELETE /bulk with body
      await _apiService.delete(
        path: ApiEndpoints.bulkDeleteAttendance,
        body: requestBody,
      );

      print('✅ [AttendanceRepository] Bulk delete successful');

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
