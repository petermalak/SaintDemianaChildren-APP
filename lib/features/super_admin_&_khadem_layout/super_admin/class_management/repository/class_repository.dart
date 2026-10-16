import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:saint_demiana_children/core/constants/api_endpoints.dart';
import 'package:saint_demiana_children/core/services/interface/i_api_service.dart';
import 'package:saint_demiana_children/core/services/sync_queue_service.dart';

import '../model/class_assignment_model.dart';
import '../model/class_members_response.dart';
import '../model/class_model.dart';
import 'i_class_repository.dart';

class ClassRepository implements IClassRepository {
  final IApiService _apiService;

  ClassRepository(this._apiService);

  List<ClassModel> _classes = [];
  List<ClassModel> _myClasses = [];
  Future<Either<String, List<ClassModel>>>? _classesFlight;
  Future<Either<String, List<ClassModel>>>? _myClassesFlight;
  DateTime? _classesAt;
  DateTime? _myClassesAt;
  static const _freshFor = Duration(minutes: 2);

  bool _isFresh(DateTime? at) =>
      at != null && DateTime.now().difference(at) < _freshFor;

  @override
  Future<Either<String, List<ClassModel>>> loadClasses() {
    if (_classes.isNotEmpty && _isFresh(_classesAt)) {
      return Future.value(Right(List<ClassModel>.from(_classes)));
    }
    final existing = _classesFlight;
    if (existing != null) return existing;
    final future = _fetchClasses();
    _classesFlight = future;
    return future.whenComplete(() => _classesFlight = null);
  }

  Future<Either<String, List<ClassModel>>> _fetchClasses() async {
    try {
      final response = await _apiService.get(path: ApiEndpoints.classes);
      _classes = response.data
          .map<ClassModel>((json) => ClassModel.fromJson(json))
          .toList();
      _classesAt = DateTime.now();
      return Right(_classes);
    } on DioException catch (e) {
      return Left(_apiService.handleError(e));
    } catch (e) {
      return const Left('حدث خطأ غير متوقع');
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
      if (response.isQueued) return const Left(kQueuedOperationMessage);
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : response.data;
      _classes.add(ClassModel.fromJson(data));
      return const Right(unit);
    } on DioException catch (e) {
      return Left(_apiService.handleError(e));
    } catch (e) {
      return const Left('حدث خطأ غير متوقع');
    }
  }

  @override
  List<ClassModel> get classes => _classes;

  @override
  List<ClassModel> get myClasses => _myClasses;

  @override
  Future<Either<String, List<ClassModel>>> loadMyClasses() {
    if (_myClasses.isNotEmpty && _isFresh(_myClassesAt)) {
      return Future.value(Right(List<ClassModel>.from(_myClasses)));
    }
    final existing = _myClassesFlight;
    if (existing != null) return existing;
    final future = _fetchMyClasses();
    _myClassesFlight = future;
    return future.whenComplete(() => _myClassesFlight = null);
  }

  Future<Either<String, List<ClassModel>>> _fetchMyClasses() async {
    try {
      final response = await _apiService.get(path: ApiEndpoints.myClasses);

      print(
          '📦 [ClassRepo] loadMyClasses: Response type: ${response.data.runtimeType}');

      // Handle different response formats
      final rawList = response.data is List
          ? response.data
          : (response.data is Map && response.data['data'] != null
              ? response.data['data']
              : response.data);

      if (rawList is! List) {
        print(
            '❌ [ClassRepo] loadMyClasses: Response is not a list: ${rawList.runtimeType}, value: $rawList');
        return const Left('صيغة الاستجابة غير صالحة');
      }

      print('📦 [ClassRepo] loadMyClasses: Received ${rawList.length} classes');

      _myClasses =
          rawList.map<ClassModel>((json) => ClassModel.fromJson(json)).toList();
      _myClassesAt = DateTime.now();
      return Right(_myClasses);
    } on DioException catch (e) {
      print('❌ [ClassRepo] loadMyClasses DioException: ${e.message}');
      print('❌ [ClassRepo] Response: ${e.response?.data}');
      return Left(_apiService.handleError(e));
    } catch (e, stackTrace) {
      print('❌ [ClassRepo] loadMyClasses error: $e');
      print('❌ [ClassRepo] Stack trace: $stackTrace');
      return const Left('حدث خطأ غير متوقع');
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
      return const Left('حدث خطأ غير متوقع');
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
      return Left('حدث خطأ غير متوقع');
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
      return Left('حدث خطأ غير متوقع');
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
      return Left('حدث خطأ غير متوقع');
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
      return const Left('حدث خطأ غير متوقع');
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
      if (response.isQueued) return const Left(kQueuedOperationMessage);

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return Right(ClassAssignmentsModel.fromJson(data));
      }
      return const Left('Unexpected response format');
    } on DioException catch (e) {
      return Left(_apiService.handleError(e));
    } catch (e) {
      return const Left('حدث خطأ غير متوقع');
    }
  }
}
