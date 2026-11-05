import 'package:dartz/dartz.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';

abstract class IAuthenticationRepository {
  Future<Either<String, UserModel>> login(
      {required String email, required String password});
  void logout();
  Future<bool> isAuthenticated();
  Future<Either<String, Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });
}
