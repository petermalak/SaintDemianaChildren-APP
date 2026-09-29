import 'package:saint_demiana_children/features/authentication/model/user_model.dart';

abstract class IStorageService {
  Future<void> init();
  Future<void> saveProfile(UserModel user);
  Future<void> updateProfile(UserModel user);
  Future<UserModel?> getProfile();
  Future<void> deleteProfile();

  /// Time of the last successful online login (used for the offline session window).
  Future<void> saveLoginTime(DateTime time);
  DateTime? getLoginTime();

  /// Offline cache of API responses, keyed by request.
  Future<void> cacheResponse(String key, dynamic data);
  dynamic getCachedResponse(String key);

  /// When this cached response was saved, if known.
  DateTime? getCacheSavedAt(String key);

  /// Newest saved response on this device.
  DateTime? getLastCacheTime();
  Future<void> clearResponseCache();
}
