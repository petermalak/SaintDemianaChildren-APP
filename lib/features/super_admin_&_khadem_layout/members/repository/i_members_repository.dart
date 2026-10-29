import 'package:dartz/dartz.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';

abstract class IMembersRepository {
  List<UserModel> members = [];
  Future<Either<String, List<UserModel>>> fetchMembers(bool isSuperAdmin,
      {String? classId, bool summary = false});

  /// Fetches members of a single class (includes Pope Athanasius data from class-members API).
  Future<Either<String, List<UserModel>>> fetchClassMembers(String classId,
      {bool summary = false});
  Future<Either<String, UserModel>> fetchMember(String userId);
  Future<Either<String, Unit>> updateMemberProfile(UserModel user);
  Future<Either<String, Unit>> addMember(UserModel user,
      {bool confirmDuplicate = false});
  Future<Either<String, Map<String, dynamic>>> findDuplicates({
    String? phoneNumber,
    String? name,
  });
  Future<Either<String, List<String>>> theaterDepartments();
  Future<Either<String, Unit>> updateTheaterDepartment(
      String userId, String? department);
  Future<Either<String, List<Map<String, dynamic>>>> fetchMemberRequests(
      {String? status});
  Future<Either<String, Map<String, dynamic>>> submitMemberRequest(
      Map<String, dynamic> body);
  Future<Either<String, Map<String, dynamic>>> approveMemberRequest(String id);
  Future<Either<String, Unit>> rejectMemberRequest(String id, String reason);
  void setMembers(List<UserModel> newMembers);
  void deleteMember(UserModel user);
}
