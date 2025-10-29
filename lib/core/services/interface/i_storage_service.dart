import 'package:saint_demiana_children/features/authentication/model/user_model.dart';

abstract class IStorageService {
  Future<void> init();
  Future<void> saveProfile(UserModel user);
  Future<void> updateProfile(UserModel user);
  Future<UserModel?> getProfile();
  Future<void> deleteProfile();
}
