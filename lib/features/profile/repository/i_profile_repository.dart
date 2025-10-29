import 'package:dartz/dartz.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';

abstract class IProfileRepository {
  Future<Either<String, Unit>> updateProfile(UserModel user);
  Future<UserModel?> loadUser();
  UserModel? get user;
  set user(UserModel? user);
  UserRole get userRole;
}
