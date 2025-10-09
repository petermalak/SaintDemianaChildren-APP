import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:saint_demiana_children/core/constants/api_endpoints.dart';
import 'package:saint_demiana_children/core/services/interface/i_api_service.dart';

import '../model/class_model.dart';
import 'i_class_repository.dart';

class ClassRepository implements IClassRepository {
  final IApiService _apiService;

  ClassRepository(this._apiService);

  List<ClassModel> _classes = [];
  @override
  Future<Either<String, List<ClassModel>>> loadClasses() async {
    try {
      final response = await _apiService.get(path: ApiEndpoints.classes);
      _classes = response.data
          .map<ClassModel>((json) => ClassModel.fromJson(json))
          .toList();
      return Right(_classes);
    } on DioException catch (e) {
      return Left(_apiService.handleError(e));
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, Unit>> addClass(String name, String location) async {
    try {
      final response = await _apiService.post(
          path: ApiEndpoints.classes,
          body: {"name": name, "location": location});
      _classes.add(ClassModel.fromJson(response.data));
      return const Right(unit);
    } on DioException catch (e) {
      return Left(_apiService.handleError(e));
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  List<ClassModel> get classes => _classes;

  @override
  void deleteClass(String classId) {
    _classes.removeWhere((c) => c.id == classId);
    _apiService.delete(path: ApiEndpoints.classes + classId);
  }

  @override
  Future<Either<String, Unit>> updateClass(String id, String name, String location) async{
    try {
       await _apiService.put(
          path: ApiEndpoints.classes+id,
          body: {"name": name, "location": location});
      final index = _classes.indexWhere((c) => c.id == id);
      _classes[index].name = name;
      _classes[index].location = location;
      return const Right(unit);
    } on DioException catch (e) {
      return Left(_apiService.handleError(e));
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  void removeUserFromClass(String classId, String userId) {
    final classModel = _classes.firstWhere((c) => c.id == classId);
    classModel.memberships?.removeWhere((m) => m.userId == userId);
    _apiService.delete(path: '${ApiEndpoints.classes}$classId/members/$userId');
  }
}
