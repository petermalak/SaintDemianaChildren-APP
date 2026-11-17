import 'package:dartz/dartz.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';

abstract class IProfileRepository {
  Future<Either<String, Unit>> updateProfile(UserModel user, {bool clearImage = false});
  Future<UserModel?> loadUser();
  Future<Either<String, UserModel>> refreshUser();
  UserModel? get user;
  set user(UserModel? user);
  UserRole get userRole;
}
