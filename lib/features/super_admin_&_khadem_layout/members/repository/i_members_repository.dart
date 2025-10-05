import 'package:dartz/dartz.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';

abstract class IMembersRepository {
  List<UserModel> members = [];
  Future<Either<String, List<UserModel>>> fetchMembers(bool isSuperAdmin);
  Future<Either<String, Unit>> updateMember(UserModel user);
  Future<Either<String, Unit>> addMember(UserModel user);
}
