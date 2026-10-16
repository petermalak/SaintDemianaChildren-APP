import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/services/interface/i_api_service.dart';
import '../model/attendance_models.dart';
import 'i_pope_attendance_repository.dart';

class PopeAttendanceRepository implements IPopeAttendanceRepository {
  PopeAttendanceRepository(this._apiService);

  final IApiService _apiService;

  @override
  Future<Either<String, LevelTwoBoard>> levelTwoBoard(String date) {
    return _load(
      ApiEndpoints.popeLevelTwoBoard,
      queryParameters: {'date': date},
      map: (data) => LevelTwoBoard.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  @override
  Future<Either<String, List<PopeCourseOption>>> levelOneCourses() {
    return _load(
      ApiEndpoints.popeLevelOneCourses,
      map: (data) => (data as List)
          .whereType<Map>()
          .map((item) => PopeCourseOption.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  @override
  @override
  Future<Either<String, MyRunningView>> myRunningCourses() {
    return _load(
      ApiEndpoints.popeMyCourse,
      map: (data) => MyRunningView.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  @override
  Future<Either<String, CourseMarks>> courseMarks(String courseId) {
    return _load(
      ApiEndpoints.popeCourseMarks(courseId),
      map: (data) => CourseMarks.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<Either<String, T>> _load<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) map,
  }) async {
    try {
      final response = await _apiService.get(
        path: path,
        queryParameters: queryParameters,
      );
      final body = response.data;
      if (body is Map && body['success'] == true) {
        return right(map(body['data']));
      }
      return left('تعذر تحميل البيانات');
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left(e.toString());
    }
  }
}
