import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:saint_demiana_children/core/constants/api_endpoints.dart';
import 'package:saint_demiana_children/core/services/interface/i_api_service.dart';

import 'package:saint_demiana_children/features/authentication/model/user_model.dart';
import 'package:saint_demiana_children/features/profile/repository/i_profile_repository.dart';

import 'i_authentication_repository.dart';

class AuthenticationRepository implements IAuthenticationRepository {
  final IApiService _apiService;
  final IProfileRepository _profileRepository;
  AuthenticationRepository(this._apiService, this._profileRepository);

  @override
  void logout() {
    _profileRepository.user = null;
    _apiService.post(path: ApiEndpoints.logout);
  }

  @override
  Future<Either<String, UserModel>> login(
      {required String email, required String password}) async {
     UserModel user;
    if (email == "superAdmin@test.com" && password == "superAdmin123") {
      user=UserModel(
          phoneNumber: "+201000000000",
          id: "1",
          name: "Super Admin",
          email: email,
          role: UserRole.superAdmin,
          token: "token");
      _profileRepository.user=user;
      return right(user);    }
      else if (email == "khadem@test.com" && password == "khadem123"){
        user=UserModel(
            phoneNumber: "+201000000001",
            id: "2",
            name: "Khadem",
            email: email,
            role: UserRole.khadem,
            token: "token");
        _profileRepository.user=user;
        return right(user);    }
    else if (email == "makhdoum@test.com" && password == "makhdoum123"){
      user=UserModel(
          phoneNumber: "+201000000002",
          id: "3",
          name: "Makhdoum",
          email: email,
          role: UserRole.makhdoum,
          token: "token");
      _profileRepository.user=user;
      return right(user);
    }

    try {
      final response = await _apiService.post(path: ApiEndpoints.login, body: {
        'email': email,
        'password': password,
      });
      _profileRepository.user = UserModel.fromJson(response.data['user'],
          token: response.data['token']);
      return right(_profileRepository.user!);
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left("An unexpected error occurred");
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return (await _profileRepository.loadUser()) != null;
  }
}
