import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:saint_demiana_children/core/services/interface/i_api_service.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/repository/i_members_repository.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/sync_queue_service.dart';

class MembersRepository implements IMembersRepository {
  final IApiService _apiService;
  @override
  List<UserModel> members = [];

  /// Last successful class roster per class (keeps QR/attendance usable offline).
  final Map<String, List<UserModel>> _classRosterById = {};

  MembersRepository(this._apiService);

  @override
  void setMembers(List<UserModel> newMembers) {
    members = newMembers;
  }

  bool _memberInClass(UserModel m, String classId) {
    if (m.classId == classId) return true;
    if (m.classes.any((c) => c.classId == classId)) return true;
    if (m.classIds?.contains(classId) == true) return true;
    return false;
  }

  List<UserModel> _offlineClassRoster(String classId) {
    final cached = _classRosterById[classId];
    if (cached != null && cached.isNotEmpty) {
      return List<UserModel>.from(cached);
    }
    if (members.isEmpty) return const [];
    return members.where((m) => _memberInClass(m, classId)).toList();
  }

  @override
  Future<Either<String, List<UserModel>>> fetchClassMembers(String classId,
      {bool summary = false}) async {
    try {
      final response = await _apiService.get(
        path: ApiEndpoints.classMembers(classId),
        queryParameters: summary ? {'summary': '1'} : null,
      );
      final data =
          response.data is Map ? response.data as Map<String, dynamic> : null;
      if (data == null) {
        final fallback = _offlineClassRoster(classId);
        if (fallback.isNotEmpty) return right(fallback);
        return left('استجابة غير صالحة');
      }
      final makhdoum = data['makhdoum'] as List<dynamic>? ?? [];
      final khadem = data['khadem'] as List<dynamic>? ?? [];
      final list = [...makhdoum, ...khadem];
      final loaded = list
          .map((e) => UserModel.fromJson(e is Map<String, dynamic>
              ? e
              : Map<String, dynamic>.from(e as Map)))
          .toList();
      _classRosterById[classId] = loaded;
      return right(loaded);
    } on DioException catch (e) {
      final fallback = _offlineClassRoster(classId);
      if (fallback.isNotEmpty) return right(fallback);
      return left(_apiService.handleError(e));
    } catch (e) {
      final fallback = _offlineClassRoster(classId);
      if (fallback.isNotEmpty) return right(fallback);
      return left('تعذر تحميل الأعضاء');
    }
  }

  Future<Either<String, List<UserModel>>>? _inFlightFetch;

  /// Startup and the members screen can ask for the list at the same time;
  /// they share one request instead of both hitting the server.
  @override
  Future<Either<String, List<UserModel>>> fetchMembers(bool isSuperAdmin,
      {String? classId, bool summary = false}) {
    if (classId != null) {
      return _fetchMembers(isSuperAdmin, classId: classId, summary: summary);
    }
    final existing = _inFlightFetch;
    if (existing != null) return existing;
    final future = _fetchMembers(isSuperAdmin, summary: summary);
    _inFlightFetch = future;
    return future.whenComplete(() => _inFlightFetch = null);
  }

  Future<Either<String, List<UserModel>>> _fetchMembers(bool isSuperAdmin,
      {String? classId, bool summary = false}) async {
    try {
      final queryParams = <String, dynamic>{
        if (classId != null) 'classId': classId,
        if (summary) 'summary': '1',
      };
      final response = await _apiService.get(
        path: isSuperAdmin ? ApiEndpoints.users : ApiEndpoints.members,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      // Backend returns { success: true, data: [...] } for GET /users/
      final rawList = response.data is Map && response.data['data'] != null
          ? response.data['data']
          : response.data;
      final list = rawList is List ? rawList : <dynamic>[];
      final members = list
          .map((memberJson) => UserModel.fromJson(
              memberJson is Map<String, dynamic>
                  ? memberJson
                  : Map<String, dynamic>.from(memberJson as Map)))
          .toList();
      if (classId == null) this.members = members;
      return right(members);
    } on DioException catch (e) {
      if (classId == null && this.members.isNotEmpty) {
        return right(List<UserModel>.from(this.members));
      }
      if (classId != null) {
        final fallback = _offlineClassRoster(classId);
        if (fallback.isNotEmpty) return right(fallback);
      }
      return left(_apiService.handleError(e));
    } catch (e) {
      print(e.toString());
      if (classId == null && this.members.isNotEmpty) {
        return right(List<UserModel>.from(this.members));
      }
      return left('حدث خطأ غير متوقع');
    }
  }

  @override
  Future<Either<String, UserModel>> fetchMember(String userId) async {
    try {
      final response = await _apiService.get(path: '${ApiEndpoints.users}$userId');
      final raw = response.data;
      if (raw is! Map) return left('استجابة غير صالحة');
      final json = raw['data'] is Map ? raw['data'] as Map : raw;
      return right(UserModel.fromJson(Map<String, dynamic>.from(json)));
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left('تعذر فتح بيانات العضو');
    }
  }

  @override
  Future<Either<String, Unit>> addMember(UserModel user,
      {bool confirmDuplicate = false}) async {
    try {
      final body = user.toJson();
      if (confirmDuplicate) body['confirmDuplicate'] = true;
      final response =
          await _apiService.post(path: ApiEndpoints.users, body: body);
      if (response.isQueued) return left(kQueuedOperationMessage);
      final raw = response.data;
      final json = raw is Map && raw['data'] is Map ? raw['data'] : raw;
      if (json is Map) {
        members.add(UserModel.fromJson(Map<String, dynamic>.from(json)));
      }
      return right(unit);
      //TODO:refresh members list and stats
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left('حدث خطأ غير متوقع');
    }
  }

  @override
  Future<Either<String, Unit>> updateMemberProfile(UserModel user) async {
    try {
      final response = await _apiService.put(
          path: ApiEndpoints.users + user.id!, body: user.toJson());
      members.removeWhere((element) => element.id == user.id);
      members.add(response.isQueued ? user : UserModel.fromJson(response.data));
      return right(unit);
      //TODO:refresh members list and stats
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left('حدث خطأ غير متوقع');
    }
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  @override
  Future<Either<String, Map<String, dynamic>>> findDuplicates({
    String? phoneNumber,
    String? name,
  }) async {
    try {
      final response = await _apiService.get(
        path: ApiEndpoints.possibleDuplicates,
        queryParameters: {
          if (phoneNumber != null && phoneNumber.isNotEmpty)
            'phoneNumber': phoneNumber,
          if (name != null && name.isNotEmpty) 'name': name,
        },
      );
      return right(_asMap(response.data));
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left('تعذر البحث عن حسابات مشابهة');
    }
  }

  @override
  Future<Either<String, List<String>>> theaterDepartments() async {
    try {
      final response =
          await _apiService.get(path: ApiEndpoints.theaterDepartments);
      final raw = response.data;
      final list = raw is List ? raw : <dynamic>[];
      return right(list.map((item) => item.toString()).toList());
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left('تعذر تحميل الأقسام');
    }
  }

  @override
  Future<Either<String, Unit>> updateTheaterDepartment(
      String userId, String? department) async {
    try {
      await _apiService.patch(
        path: ApiEndpoints.theaterProfile(userId),
        body: {'department': department},
      );
      return right(unit);
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left('تعذر حفظ القسم');
    }
  }

  @override
  Future<Either<String, List<Map<String, dynamic>>>> fetchMemberRequests(
      {String? status}) async {
    try {
      final response = await _apiService.get(
        path: ApiEndpoints.userRequests,
        queryParameters: status == null ? null : {'status': status},
      );
      final raw = response.data;
      final list = raw is List ? raw : <dynamic>[];
      return right(list.map(_asMap).toList());
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left('تعذر تحميل الطلبات');
    }
  }

  @override
  Future<Either<String, Map<String, dynamic>>> submitMemberRequest(
      Map<String, dynamic> body) async {
    try {
      final response =
          await _apiService.post(path: ApiEndpoints.userRequests, body: body);
      return right(_asMap(response.data));
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['data'] is Map) {
        return left('duplicate:${data['message'] ?? ''}');
      }
      return left(_apiService.handleError(e));
    } catch (e) {
      return left('تعذر إرسال الطلب');
    }
  }

  @override
  Future<Either<String, Map<String, dynamic>>> approveMemberRequest(
      String id) async {
    try {
      final response = await _apiService.post(
        path: ApiEndpoints.approveUserRequest(id),
        body: const {},
      );
      return right(_asMap(response.data));
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left('تعذر الموافقة');
    }
  }

  @override
  Future<Either<String, Unit>> rejectMemberRequest(
      String id, String reason) async {
    try {
      await _apiService.post(
        path: ApiEndpoints.rejectUserRequest(id),
        body: {'reason': reason},
      );
      return right(unit);
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left('تعذر رفض الطلب');
    }
  }

  @override
  void deleteMember(UserModel user) {
    _apiService.delete(path: ApiEndpoints.users + user.id!);
    members.removeWhere((element) => element.id == user.id);
    //TODO:refresh members list and stats
  }
}
