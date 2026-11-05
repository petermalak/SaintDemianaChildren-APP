import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  final String _loginTimeKey = 'last_login_at';
  final String _lastCacheAtKey = 'last_api_cache_at';
  final String _apiCacheBox = 'apiCacheBox';
  static const String _authTokenKey = 'auth_access_token';

  final FlutterSecureStorage? _secureStorage = kIsWeb
      ? null
      : const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  Future<void> _persistAuthToken(String? token) async {
    if (kIsWeb) return;
    final storage = _secureStorage;
    if (storage == null) return;
    if (token != null && token.isNotEmpty) {
      await storage.write(key: _authTokenKey, value: token);
    } else {
      await storage.delete(key: _authTokenKey);
    }
  }

  @override
  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_userBox);
    await Hive.openBox(_apiCacheBox);
  }

  @override
  Future<void> deleteProfile() async {
    final box = Hive.box(_userBox);
    await box.delete(_userKey);
    await box.delete(_loginTimeKey);
    await box.delete(_lastCacheAtKey);
    await _persistAuthToken(null);
    await clearResponseCache();
  }

  @override
  Future<void> saveLoginTime(DateTime time) async {
    await Hive.box(_userBox).put(_loginTimeKey, time.toIso8601String());
  }

  @override
  DateTime? getLoginTime() {
    final raw = Hive.box(_userBox).get(_loginTimeKey);
    return raw is String ? DateTime.tryParse(raw) : null;
  }

  @override
  Future<void> cacheResponse(String key, dynamic data) async {
    try {
      final savedAt = DateTime.now().toUtc();
      await Hive.box(_apiCacheBox).put(
        key,
        jsonEncode({
          'savedAt': savedAt.toIso8601String(),
          'data': data,
        }),
      );
      await Hive.box(_userBox).put(_lastCacheAtKey, savedAt.toIso8601String());
    } catch (e) {
      print('⚠️ [StorageService] Could not cache response for $key: $e');
    }
  }

  Map<String, dynamic>? _readCacheEnvelope(String key) {
    final raw = Hive.box(_apiCacheBox).get(key);
    if (raw is! String) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded.containsKey('data')) {
        return Map<String, dynamic>.from(decoded);
      }
      return {'data': decoded};
    } catch (_) {
      return null;
    }
  }

  @override
  dynamic getCachedResponse(String key) => _readCacheEnvelope(key)?['data'];

  @override
  DateTime? getCacheSavedAt(String key) {
    final savedAt = _readCacheEnvelope(key)?['savedAt'];
    return savedAt is String ? DateTime.tryParse(savedAt) : null;
  }

  @override
  DateTime? getLastCacheTime() {
    final raw = Hive.box(_userBox).get(_lastCacheAtKey);
    return raw is String ? DateTime.tryParse(raw) : null;
  }

  @override
  Future<void> clearResponseCache() async {
    await Hive.box(_apiCacheBox).clear();
  }

  @override
  Future<UserModel?> getProfile() async {
    try {
      final box = Hive.box(_userBox);
      final userData = box.get(_userKey);

      if (userData != null && userData is Map) {
        final map = Map<String, dynamic>.from(userData);
        print('📦 [StorageService] User data retrieved from Hive');
        print('📦 [StorageService] Token in storage: ${map['token'] != null}');

        if (map['token'] != null) {
          print(
              '📦 [StorageService] Token preview: ${map['token'].toString().substring(0, 20)}...');
        } else {
          print('⚠️ [StorageService] WARNING: No token in stored user data!');
          print('⚠️ [StorageService] Available keys: ${map.keys.toList()}');
        }

        UserModel model =
            UserModel.fromJson(map, token: map['token']?.toString());

        final t = model.token;
        if ((t == null || t.isEmpty) && _secureStorage != null) {
          final fromSecure = await _secureStorage!.read(key: _authTokenKey);
          if (fromSecure != null && fromSecure.isNotEmpty) {
            model = model.copyWith(token: fromSecure);
            await box.put(_userKey, model.toJson());
            print('📦 [StorageService] Restored auth token from secure storage');
          }
        }

        return model;
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
    await _persistAuthToken(user.token);
    print('✅ [StorageService] User profile saved successfully');
  }

  @override
  Future<void> updateProfile(UserModel user) async {
    final box = Hive.box(_userBox);
    UserModel toSave = user;
    final incoming = user.token;
    if (incoming == null || incoming.isEmpty) {
      final raw = box.get(_userKey);
      if (raw is Map) {
        final existing =
            Map<String, dynamic>.from(raw)['token']?.toString();
        if (existing != null && existing.isNotEmpty) {
          toSave = user.copyWith(token: existing);
        }
      }
      if ((toSave.token == null || toSave.token!.isEmpty) &&
          _secureStorage != null) {
        final fromSecure = await _secureStorage!.read(key: _authTokenKey);
        if (fromSecure != null && fromSecure.isNotEmpty) {
          toSave = user.copyWith(token: fromSecure);
        }
      }
    }
    await box.put(_userKey, toSave.toJson());
    await _persistAuthToken(toSave.token);
  }
}
