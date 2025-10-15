import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:saint_demiana_children/core/constants/api_endpoints.dart';
import 'package:saint_demiana_children/core/services/interface/i_api_service.dart';
import 'package:saint_demiana_children/core/services/interface/i_storage_service.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';
import 'package:saint_demiana_children/features/profile/repository/i_profile_repository.dart';

class ProfileRepository implements IProfileRepository {
  final IApiService _apiService;
  final IStorageService _storageService;
  ProfileRepository(this._apiService, this._storageService);
  UserModel? _user;

  @override
  UserModel? get user => _user;

  @override
  Future<UserModel?> loadUser() async {
    if (_user != null) return _user;
    _user = await _storageService.getProfile();
    return _user;
  }

  @override
  UserRole get userRole => _user?.role ?? UserRole.makhdoum;

  @override
  set user(UserModel? user) {
    if (user != null) {
      _storageService.saveProfile(user);
    } else {
      _storageService.deleteProfile();
    }
    _user = user;
  }

  @override
  Future<Either<String, Unit>> updateProfile(UserModel user) async {
    try {
      await _apiService.put(path: ApiEndpoints.myProfile, body: user.toJson());
      await _storageService.updateProfile(user);
      return right(unit);
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left("Unexpected error occurred");
    }
  }
}
