import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:saint_demiana_children/core/constants/api_endpoints.dart';
import 'package:saint_demiana_children/core/services/interface/i_api_service.dart';
import 'package:saint_demiana_children/core/services/interface/i_biometric_service.dart';

import 'package:saint_demiana_children/features/authentication/model/user_model.dart';
import 'package:saint_demiana_children/features/profile/repository/i_profile_repository.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/repository/i_members_repository.dart';

import 'i_authentication_repository.dart';

class AuthenticationRepository implements IAuthenticationRepository {
  final IApiService _apiService;
  final IProfileRepository _profileRepository;
  final IMembersRepository _membersRepository;
  final IBiometricService _biometricService;
  AuthenticationRepository(this._apiService, this._profileRepository,
      this._membersRepository, this._biometricService);

  @override
  void logout() {
    _profileRepository.user = null;
    _apiService.post(path: ApiEndpoints.logout);
  }

  @override
  Future<Either<String, UserModel>> login(
      {required String email, required String password}) async {
    // UserModel user;
    // if (email == "superAdmin@test.com" && password == "superAdmin123") {
    //   user = UserModel(
    //       phoneNumber: "+201000000000",
    //       id: "1",
    //       name: "Super Admin",
    //       email: email,
    //       role: UserRole.superAdmin,
    //       token: "token");
    //   _profileRepository.user = user;
    //   return right(user);
    // } else if (email == "khadem@test.com" && password == "khadem123") {
    //   user = UserModel(
    //       phoneNumber: "+201000000001",
    //       id: "2",
    //       name: "Khadem",
    //       email: email,
    //       role: UserRole.khadem,
    //       token: "token");
    //   _profileRepository.user = user;
    //   return right(user);
    // } else if (email == "makhdoum@test.com" && password == "makhdoum123") {
    //   user = UserModel(
    //       phoneNumber: "+201000000002",
    //       id: "3",
    //       name: "Makhdoum",
    //       email: email,
    //       role: UserRole.makhdoum,
    //       token: "token");
    //   _profileRepository.user = user;
    //   return right(user);
    // }

    try {
      print('🔐 [AuthRepo] Attempting login for: $email');

      final response = await _apiService.post(path: ApiEndpoints.login, body: {
        'email': email,
        'password': password,
      });

      print('✅ [AuthRepo] Login successful');
      print('🔐 [AuthRepo] Token received: ${response.data['token'] != null}');

      if (response.data['token'] != null) {
        print(
            '🔐 [AuthRepo] Token preview: ${response.data['token'].toString().substring(0, 20)}...');
      }

      final user = UserModel.fromJson(response.data['user'],
          token: response.data['token']);

      print('👤 [AuthRepo] User created: ${user.name}');
      print('🔐 [AuthRepo] User has token: ${user.token != null}');

      // This setter saves to storage
      _profileRepository.user = user;

      print('💾 [AuthRepo] User saved to ProfileRepository');

      // Save credentials for biometric login (only on mobile platforms)
      // This allows users to use fingerprint/Face ID for future logins
      if (!kIsWeb && _biometricService.isSupported) {
        try {
          await _biometricService.saveCredentials(email, password);
          if (kDebugMode) {
            print('✅ [AuthRepo] Credentials saved for biometric login');
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ [AuthRepo] Failed to save credentials for biometric: $e');
          }
          // Don't fail login if credential saving fails - biometric is optional
        }
      }

      if (_profileRepository.user?.role != UserRole.makhdoum) {
        print("=============================================");
        print('🔄 [AuthRepo] Fetching members...');
        (await _membersRepository.fetchMembers(
                _profileRepository.user?.role == UserRole.superAdmin))
            .fold((error) {
          throw error;
        }, (_) {});
        print('✅ [AuthRepo] Members fetched');
        print("=============================================");
      }
      return right(_profileRepository.user!);
    } on DioException catch (e) {
      print('❌ [AuthRepo] DioException during login: ${e.message}');
      return left(_apiService.handleError(e));
    } catch (e) {
      print('❌ [AuthRepo] Error during login: $e');
      return left(e.toString());
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return (await _profileRepository.loadUser()) != null;
  }

  @override
  Future<Either<String, Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      print('🔐 [AuthRepo] Attempting to change password...');

      await _apiService.post(
        path: ApiEndpoints.changePassword,
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );

      print('✅ [AuthRepo] Password changed successfully');
      return right(unit);
    } on DioException catch (e) {
      print('❌ [AuthRepo] DioException during password change: ${e.message}');
      return left(_apiService.handleError(e));
    } catch (e) {
      print('❌ [AuthRepo] Error during password change: $e');
      return left(e.toString());
    }
  }
}
