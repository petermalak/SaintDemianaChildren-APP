import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:saint_demiana_children/core/constants/api_endpoints.dart';
import 'package:saint_demiana_children/core/services/interface/i_api_service.dart';

import '../model/class_assignment_model.dart';
import '../model/class_members_response.dart';
import '../model/class_model.dart';
import 'i_class_repository.dart';

class ClassRepository implements IClassRepository {
  final IApiService _apiService;

  ClassRepository(this._apiService);

  List<ClassModel> _classes = [];
  List<ClassModel> _myClasses = [];
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
  Future<Either<String, Unit>> addClass(String name, String location,
      {bool hasShop = false}) async {
    try {
      final response =
          await _apiService.post(path: ApiEndpoints.classes, body: {
        "name": name,
        "location": location,
        "hasShop": hasShop,
      });
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : response.data;
      _classes.add(ClassModel.fromJson(data));
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
  List<ClassModel> get myClasses => _myClasses;

  @override
  Future<Either<String, List<ClassModel>>> loadMyClasses() async {
    try {
      final response = await _apiService.get(path: ApiEndpoints.myClasses);

      print(
          '📦 [ClassRepo] loadMyClasses: Response type: ${response.data.runtimeType}');
      print('📦 [ClassRepo] loadMyClasses: Response data: ${response.data}');

      // Handle different response formats
      final rawList = response.data is List
          ? response.data
          : (response.data is Map && response.data['data'] != null
              ? response.data['data']
              : response.data);

      if (rawList is! List) {
        print(
            '❌ [ClassRepo] loadMyClasses: Response is not a list: ${rawList.runtimeType}, value: $rawList');
        return const Left('Invalid response format');
      }

      print('📦 [ClassRepo] loadMyClasses: Received ${rawList.length} classes');
      for (var i = 0; i < rawList.length; i++) {
        final item = rawList[i];
        print('  [$i] Class JSON: ${item.toString()}');
        print(
            '  [$i] Class name: ${item['name']}, hasShop: ${item['hasShop']} (type: ${item['hasShop']?.runtimeType}, value: ${item['hasShop']})');
      }

      _myClasses = rawList.map<ClassModel>((json) {
        final model = ClassModel.fromJson(json);
        print(
            '  ✅ Parsed ClassModel: ${model.name}, hasShop: ${model.hasShop}');
        return model;
      }).toList();
      return Right(_myClasses);
    } on DioException catch (e) {
      print('❌ [ClassRepo] loadMyClasses DioException: ${e.message}');
      print('❌ [ClassRepo] Response: ${e.response?.data}');
      return Left(_apiService.handleError(e));
    } catch (e, stackTrace) {
      print('❌ [ClassRepo] loadMyClasses error: $e');
      print('❌ [ClassRepo] Stack trace: $stackTrace');
      return Left('An unexpected error occurred: $e');
    }
  }

  @override
  void deleteClass(String classId) {
    _classes.removeWhere((c) => c.id == classId);
    _apiService.delete(path: ApiEndpoints.classes + classId);
  }

  @override
  Future<Either<String, Unit>> updateClass(
      String id, String name, String location,
      {bool? hasShop}) async {
    try {
      final body = <String, dynamic>{"name": name, "location": location};
      if (hasShop != null) body["hasShop"] = hasShop;
      await _apiService.put(path: ApiEndpoints.classes + id, body: body);
      final index = _classes.indexWhere((c) => c.id == id);
      _classes[index] = _classes[index].copyWith(
        name: name,
        location: location,
        hasShop: hasShop ?? _classes[index].hasShop,
      );
      return const Right(unit);
    } on DioException catch (e) {
      return Left(_apiService.handleError(e));
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, Unit>> removeUserFromClass(
      String classId, String userId) async {
    try {
      await _apiService.delete(
          path: '${ApiEndpoints.classMembers(classId)}/$userId');
      return const Right(unit);
    } on DioException catch (e) {
      return Left(_apiService.handleError(e));
    } catch (e) {
      return Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, ClassMembersResponse>> getClassMembers(
      String classId) async {
    try {
      final response =
          await _apiService.get(path: ApiEndpoints.classMembers(classId));
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      return Right(ClassMembersResponse.fromJson(data));
    } on DioException catch (e) {
      return Left(_apiService.handleError(e));
    } catch (e) {
      return Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, Unit>> addClassMember(
    String classId,
    String userId,
    String role, {
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{
        'userId': userId,
        'role': role,
      };
      if (notes != null && notes.isNotEmpty) body['notes'] = notes;
      await _apiService.post(
        path: ApiEndpoints.classMembers(classId),
        body: body,
      );
      return const Right(unit);
    } on DioException catch (e) {
      return Left(_apiService.handleError(e));
    } catch (e) {
      return Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, ClassAssignmentsModel>> loadClassAssignments(
      String classId) async {
    try {
      final response =
          await _apiService.get(path: ApiEndpoints.classAssignments(classId));
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return Right(ClassAssignmentsModel.fromJson(data));
      }
      return const Left('Unexpected response format');
    } on DioException catch (e) {
      return Left(_apiService.handleError(e));
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, ClassAssignmentsModel>> updateClassAssignments(
    String classId,
    Map<String, Set<String>> assignments, {
    Map<String, Map<String, String?>>? notes,
  }) async {
    try {
      final payload = {
        'assignments':
            ClassAssignmentsModel.buildUpdatePayload(assignments, notes: notes),
      };

      final response = await _apiService.put(
        path: ApiEndpoints.classAssignments(classId),
        body: payload,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return Right(ClassAssignmentsModel.fromJson(data));
      }
      return const Left('Unexpected response format');
    } on DioException catch (e) {
      return Left(_apiService.handleError(e));
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }
}
