import 'package:dartz/dartz.dart';
import '../model/attendance_models.dart';

abstract class IPopeAttendanceRepository {
  Future<Either<String, LevelTwoBoard>> levelTwoBoard(String date);
  Future<Either<String, List<PopeCourseOption>>> levelOneCourses();
  Future<Either<String, CourseMarks>> courseMarks(String courseId);
  Future<Either<String, MyRunningView>> myRunningCourses();
}
