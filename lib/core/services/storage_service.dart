import 'package:hive_flutter/adapters.dart';
import 'package:saint_demiana_children/core/services/interface/i_storage_service.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';

class StorageService implements IStorageService {
  static final StorageService _instance = StorageService._internal();

  StorageService._internal();

  factory StorageService() => _instance;

  static StorageService get instance => _instance;

  final String _userBox = 'userBox';
  final String _userKey = 'user_profile';

  @override
  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_userBox);
  }

  @override
  Future<void> deleteProfile() async {
    final box = Hive.box(_userBox);
    await box.delete(_userKey);
  }

  @override
  Future<UserModel?> getProfile() async {
    try {
      final box = Hive.box(_userBox);
      final userData = box.get(_userKey);
      if (userData != null) {
        return UserModel.fromJson(userData, token: userData['token']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveProfile(UserModel user) async {
    final box = Hive.box(_userBox);
    await box.put(_userKey, user.toJson());
  }

  @override
  Future<void> updateProfile(UserModel user) async {
    final box = Hive.box(_userBox);
    await box.put(_userKey, user.toJson());
  }
}
