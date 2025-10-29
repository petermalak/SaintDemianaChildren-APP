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
        print('📦 [StorageService] User data retrieved from Hive');
        print(
            '📦 [StorageService] Token in storage: ${userData['token'] != null}');

        if (userData['token'] != null) {
          print(
              '📦 [StorageService] Token preview: ${userData['token'].toString().substring(0, 20)}...');
        } else {
          print('⚠️ [StorageService] WARNING: No token in stored user data!');
          print(
              '⚠️ [StorageService] Available keys: ${userData.keys.toList()}');
        }

        return UserModel.fromJson(userData, token: userData['token']);
      }

      print('📦 [StorageService] No user data in storage');
      return null;
    } catch (e) {
      print('❌ [StorageService] Error loading profile: $e');
      return null;
    }
  }

  @override
  Future<void> saveProfile(UserModel user) async {
    final box = Hive.box(_userBox);
    final jsonData = user.toJson();

    print('💾 [StorageService] Saving user profile: ${user.name}');
    print(
        '💾 [StorageService] Token being saved: ${jsonData['token'] != null}');

    if (jsonData['token'] != null) {
      print(
          '💾 [StorageService] Token preview: ${jsonData['token'].toString().substring(0, 20)}...');
    } else {
      print('⚠️ [StorageService] WARNING: Saving user WITHOUT token!');
    }

    await box.put(_userKey, jsonData);
    print('✅ [StorageService] User profile saved successfully');
  }

  @override
  Future<void> updateProfile(UserModel user) async {
    final box = Hive.box(_userBox);
    await box.put(_userKey, user.toJson());
  }
}
