import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:saint_demiana_children/core/services/interface/i_api_service.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/repository/i_members_repository.dart';

import '../../../../core/constants/api_endpoints.dart';

class MembersRepository implements IMembersRepository {
  final IApiService _apiService;
  @override
  List<UserModel> members = [];
  MembersRepository(this._apiService);

  @override
  void setMembers(List<UserModel> newMembers) {
    members = newMembers;
  }

  @override
  Future<Either<String, List<UserModel>>> fetchClassMembers(
      String classId) async {
    try {
      final response = await _apiService.get(
        path: ApiEndpoints.classMembers(classId),
      );
      final data =
          response.data is Map ? response.data as Map<String, dynamic> : null;
      if (data == null) return left('Invalid response');
      final makhdoum = data['makhdoum'] as List<dynamic>? ?? [];
      final khadem = data['khadem'] as List<dynamic>? ?? [];
      final list = [...makhdoum, ...khadem];
      final members = list
          .map((e) => UserModel.fromJson(e is Map<String, dynamic>
              ? e
              : Map<String, dynamic>.from(e as Map)))
          .toList();
      return right(members);
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left(e.toString());
    }
  }

  @override
  Future<Either<String, List<UserModel>>> fetchMembers(bool isSuperAdmin,
      {String? classId}) async {
    try {
      final queryParams = classId != null ? {'classId': classId} : null;
      final response = await _apiService.get(
        path: isSuperAdmin ? ApiEndpoints.users : ApiEndpoints.members,
        queryParameters: queryParams,
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
      this.members = members;
      return right(members);
      // return right([
      //   UserModel(
      //       id: "1",
      //       name: "John Doe",
      //       email: "",
      //       role: UserRole.makhdoum,
      //       phoneNumber: '',
      //       createdAt: DateTime.now()),
      //   UserModel(
      //       id: "2",
      //       name: "Jane Smith",
      //       email: "",
      //       role: UserRole.makhdoum,
      //       phoneNumber: '',
      //       createdAt: DateTime.now()),
      //   UserModel(
      //       id: "3",
      //       name: "Alice Johnson",
      //       email: "",
      //       role: UserRole.makhdoum,
      //       phoneNumber: '',
      //       createdAt: DateTime.now()),
      // ]);
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      print(e.toString());
      return left(e.toString());
    }
  }

  @override
  Future<Either<String, Unit>> addMember(UserModel user) async {
    try {
      print("cccccccccccccccccccccccccccccccccccccc");
      final response =
          await _apiService.post(path: ApiEndpoints.users, body: user.toJson());
      print("xxxxxxxxxxxxxxxxxxx");
      members.add(UserModel.fromJson(response.data));
      return right(unit);
      //TODO:refresh members list and stats
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left("An unexpected error occurred");
    }
  }

  @override
  Future<Either<String, Unit>> updateMemberProfile(UserModel user) async {
    try {
      final response = await _apiService.put(
          path: ApiEndpoints.users + user.id!, body: user.toJson());
      members.removeWhere((element) => element.id == user.id);
      members.add(UserModel.fromJson(response.data));
      return right(unit);
      //TODO:refresh members list and stats
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left("An unexpected error occurred");
    }
  }

  @override
  void deleteMember(UserModel user) {
    _apiService.delete(path: ApiEndpoints.users + user.id!);
    members.removeWhere((element) => element.id == user.id);
    //TODO:refresh members list and stats
  }
}
