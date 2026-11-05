import 'package:dartz/dartz.dart';

/// Interface for biometric authentication service.
/// 
/// Provides methods for fingerprint and Face ID authentication.
/// Only available on mobile platforms (Android/iOS).
/// Web platform methods will return safe defaults.
abstract class IBiometricService {
  /// Checks if biometric authentication is available on the device.
  /// 
  /// Returns `true` if the device supports biometric authentication
  /// and has at least one biometric method enrolled.
  Future<bool> isAvailable();

  /// Checks if biometric authentication is supported on the current platform.
  /// 
  /// Returns `false` for web platform, `true` for mobile platforms.
  bool get isSupported;

  /// Gets the list of available biometric types on the device.
  /// 
  /// Returns a list of biometric type names (e.g., 'fingerprint', 'face', 'iris').
  /// Returns empty list on web or if no biometrics are available.
  Future<List<String>> getAvailableBiometrics();

  /// Authenticates the user using biometrics.
  /// 
  /// [localizedReason] - The reason shown to the user in the authentication dialog.
  /// [useErrorDialogs] - Whether to show error dialogs automatically.
  /// [stickyAuth] - Whether to keep authentication active after app goes to background.
  /// 
  /// Returns `Right(true)` if authentication is successful,
  /// `Left(errorMessage)` if authentication fails or is cancelled.
  Future<Either<String, bool>> authenticate({
    String localizedReason = 'Authenticate to login',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  });

  /// Checks if credentials are saved for biometric login.
  /// 
  /// Returns `true` if both email and password are saved securely.
  Future<bool> hasSavedCredentials();

  /// Saves credentials securely for biometric login.
  /// 
  /// [email] - User's email address.
  /// [password] - User's password.
  /// 
  /// Throws [ArgumentError] if email or password is empty.
  /// Throws platform-specific exceptions if storage fails.
  Future<void> saveCredentials(String email, String password);

  /// Retrieves saved credentials for biometric login.
  /// 
  /// Returns a map with 'email' and 'password' keys if credentials exist,
  /// `null` if no credentials are saved or on web platform.
  Future<Map<String, String>?> getSavedCredentials();

  /// Deletes saved credentials from secure storage.
  /// 
  /// Does nothing on web platform.
  Future<void> deleteCredentials();
}

