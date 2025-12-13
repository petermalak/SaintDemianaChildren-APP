import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:saint_demiana_children/core/services/interface/i_biometric_service.dart';
import 'package:saint_demiana_children/core/services/logging_service.dart';

/// Service for handling biometric authentication (fingerprint/Face ID)
/// Only available on mobile platforms (Android/iOS)
class BiometricService implements IBiometricService {
  static final BiometricService _instance = BiometricService._internal();
  
  factory BiometricService() => _instance;
  
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _emailKey = 'biometric_email';
  static const String _passwordKey = 'biometric_password';
  
  static const String _defaultAuthReason = 'Authenticate to login';
  static const String _tag = 'BiometricService';
  
  LoggingService get _logger => LoggingService.instance;

  @override
  bool get isSupported => !kIsWeb;

  @override
  Future<bool> isAvailable() async {
    if (kIsWeb) {
      _logger.debug('Biometric not available on web platform', tag: _tag);
      return false;
    }
    
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      final available = canCheck || isSupported;
      
      _logger.debug(
        'Biometric availability: canCheck=$canCheck, isSupported=$isSupported',
        tag: _tag,
      );
      
      return available;
    } catch (e) {
      _logger.error(
        'Error checking biometric availability',
        tag: _tag,
        error: e,
      );
      return false;
    }
  }

  @override
  Future<List<String>> getAvailableBiometrics() async {
    if (kIsWeb) return [];
    
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      final biometricNames = availableBiometrics
          .map((biometric) => biometric.toString().split('.').last)
          .toList();
      
      _logger.debug(
        'Available biometrics: $biometricNames',
        tag: _tag,
      );
      
      return biometricNames;
    } catch (e) {
      _logger.error(
        'Error getting available biometrics',
        tag: _tag,
        error: e,
      );
      return [];
    }
  }

  @override
  Future<Either<String, bool>> authenticate({
    String localizedReason = _defaultAuthReason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    if (kIsWeb) {
      const errorMessage = 'Biometric authentication is not supported on web';
      _logger.warning(errorMessage, tag: _tag);
      return const Left(errorMessage);
    }

    try {
      final available = await isAvailable();
      if (!available) {
        const errorMessage =
            'Biometric authentication is not available on this device';
        _logger.warning(errorMessage, tag: _tag);
        return const Left(errorMessage);
      }

      _logger.debug('Starting biometric authentication', tag: _tag);
      
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        _logger.info('Biometric authentication successful', tag: _tag);
        return const Right(true);
      } else {
        const errorMessage = 'Authentication cancelled or failed';
        _logger.warning(errorMessage, tag: _tag);
        return const Left(errorMessage);
      }
    } catch (e) {
      final errorMessage = 'Authentication error: ${e.toString()}';
      _logger.error(
        'Biometric authentication failed',
        tag: _tag,
        error: e,
      );
      return Left(errorMessage);
    }
  }

  @override
  Future<bool> hasSavedCredentials() async {
    if (kIsWeb) return false;
    
    try {
      final email = await _secureStorage.read(key: _emailKey);
      final password = await _secureStorage.read(key: _passwordKey);
      final hasCredentials = email != null &&
          password != null &&
          email.isNotEmpty &&
          password.isNotEmpty;
      
      _logger.debug(
        'Saved credentials check: ${hasCredentials ? "found" : "not found"}',
        tag: _tag,
      );
      
      return hasCredentials;
    } catch (e) {
      _logger.error(
        'Error checking saved credentials',
        tag: _tag,
        error: e,
      );
      return false;
    }
  }

  @override
  Future<void> saveCredentials(String email, String password) async {
    if (kIsWeb) {
      _logger.debug('Skipping credential save on web platform', tag: _tag);
      return;
    }
    
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw ArgumentError('Email and password cannot be empty');
    }
    
    try {
      await _secureStorage.write(key: _emailKey, value: email.trim());
      await _secureStorage.write(key: _passwordKey, value: password.trim());
      _logger.info('Credentials saved securely for biometric login', tag: _tag);
    } catch (e) {
      _logger.error(
        'Error saving credentials',
        tag: _tag,
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<Map<String, String>?> getSavedCredentials() async {
    if (kIsWeb) return null;
    
    try {
      final email = await _secureStorage.read(key: _emailKey);
      final password = await _secureStorage.read(key: _passwordKey);

      if (email != null && password != null && email.isNotEmpty && password.isNotEmpty) {
        _logger.debug('Retrieved saved credentials', tag: _tag);
        return {
          'email': email,
          'password': password,
        };
      }
      
      _logger.debug('No saved credentials found', tag: _tag);
      return null;
    } catch (e) {
      _logger.error(
        'Error getting saved credentials',
        tag: _tag,
        error: e,
      );
      return null;
    }
  }

  @override
  Future<void> deleteCredentials() async {
    if (kIsWeb) {
      _logger.debug('Skipping credential deletion on web platform', tag: _tag);
      return;
    }
    
    try {
      await _secureStorage.delete(key: _emailKey);
      await _secureStorage.delete(key: _passwordKey);
      _logger.info('Biometric credentials deleted', tag: _tag);
    } catch (e) {
      _logger.error(
        'Error deleting credentials',
        tag: _tag,
        error: e,
      );
      rethrow;
    }
  }
}

