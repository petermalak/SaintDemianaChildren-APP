import 'package:dartz/dartz.dart';
import '../model/class_model.dart';

abstract class IClassRepository {
  Future<Either<String, List<ClassModel>>> loadClasses();
  List<ClassModel> get classes;
  Future<Either<String, List<ClassModel>>> loadMyClasses();
  List<ClassModel> get myClasses;
  Future<Either<String, Unit>> addClass(String name, String location);
  Future<Either<String, Unit>> updateClass(
      String id, String name, String location);
  void removeUserFromClass(String classId, String userId);
  void deleteClass(String classId);
}
