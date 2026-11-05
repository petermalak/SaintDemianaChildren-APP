import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/core/services/interface/i_biometric_service.dart';
import 'package:saint_demiana_children/features/authentication/repository/i_authentication_repository.dart';

import '../model/user_model.dart';

part 'login_state.dart';

/// Cubit for managing login state and authentication logic.
/// 
/// Handles both traditional email/password login and biometric authentication.
class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._authenticationRepository, this._biometricService)
      : super(LoginInitial());
  
  final IAuthenticationRepository _authenticationRepository;
  final IBiometricService _biometricService;

  // Error messages
  static const String _errorBiometricNotSupported =
      'Biometric authentication is not supported on this platform';
  static const String _errorBiometricNotAvailable =
      'Biometric authentication is not available on this device';
  static const String _errorNoSavedCredentials =
      'No saved credentials found. Please login with email and password first.';
  static const String _errorRetrieveCredentials =
      'Failed to retrieve saved credentials';
  static const String _biometricAuthReason =
      'Authenticate to login to your account';

  /// Logs in the user with email and password.
  /// 
  /// [email] - User's email address.
  /// [password] - User's password.
  /// 
  /// Emits [LoginLoading] during authentication,
  /// [LoginSuccess] on success, or [LoginFailure] on error.
  Future<void> login(String email, String password) async {
    if (state is LoginLoading) return;
    
    emit(LoginLoading());

    final result = await _authenticationRepository.login(
      email: email.trim(),
      password: password.trim(),
    );

    result.fold(
      (error) => emit(LoginFailure(error)),
      (user) => emit(LoginSuccess(user)),
    );
  }

  /// Logs in the user using biometric authentication.
  /// 
  /// Performs the following steps:
  /// 1. Checks if biometric authentication is supported
  /// 2. Checks if biometric authentication is available
  /// 3. Checks if credentials are saved
  /// 4. Authenticates with biometrics
  /// 5. Retrieves saved credentials and logs in
  /// 
  /// Emits [LoginLoading] during authentication,
  /// [LoginSuccess] on success, or [LoginFailure] on error.
  Future<void> loginWithBiometrics() async {
    if (state is LoginLoading) return;

    // Validate biometric support
    if (!_biometricService.isSupported) {
      emit(LoginFailure(_errorBiometricNotSupported));
      return;
    }

    // Check availability
    final isAvailable = await _biometricService.isAvailable();
    if (!isAvailable) {
      emit(LoginFailure(_errorBiometricNotAvailable));
      return;
    }

    // Check for saved credentials
    final hasCredentials = await _biometricService.hasSavedCredentials();
    if (!hasCredentials) {
      emit(LoginFailure(_errorNoSavedCredentials));
      return;
    }

    emit(LoginLoading());

    // Authenticate with biometrics
    final authResult = await _biometricService.authenticate(
      localizedReason: _biometricAuthReason,
    );

    await authResult.fold(
      (error) async {
        emit(LoginFailure(error));
      },
      (_) async {
        await _performLoginWithSavedCredentials();
      },
    );
  }

  /// Performs login using saved credentials after biometric authentication.
  Future<void> _performLoginWithSavedCredentials() async {
    final credentials = await _biometricService.getSavedCredentials();
    if (credentials == null) {
      emit(LoginFailure(_errorRetrieveCredentials));
      return;
    }

    final email = credentials['email'];
    final password = credentials['password'];

    if (email == null || password == null) {
      emit(LoginFailure(_errorRetrieveCredentials));
      return;
    }

    final result = await _authenticationRepository.login(
      email: email.trim(),
      password: password.trim(),
    );

    result.fold(
      (error) => emit(LoginFailure(error)),
      (user) => emit(LoginSuccess(user)),
    );
  }

  /// Checks if biometric authentication is available and ready to use.
  /// 
  /// Returns `true` if:
  /// - Biometric authentication is supported on the platform
  /// - Biometric authentication is available on the device
  /// - Credentials are saved for biometric login
  Future<bool> checkBiometricAvailability() async {
    if (kDebugMode) {
      print('🔍 [LoginCubit] Checking biometric availability...');
    }
    
    if (!_biometricService.isSupported) {
      if (kDebugMode) {
        print('❌ [LoginCubit] Biometric not supported');
      }
      return false;
    }
    
    final isAvailable = await _biometricService.isAvailable();
    if (kDebugMode) {
      print('📱 [LoginCubit] Biometric available: $isAvailable');
    }
    
    final hasCredentials = await _biometricService.hasSavedCredentials();
    if (kDebugMode) {
      print('🔐 [LoginCubit] Has saved credentials: $hasCredentials');
    }
    
    final result = isAvailable && hasCredentials;
    if (kDebugMode) {
      print('✅ [LoginCubit] Biometric login available: $result');
    }
    
    return result;
  }
}
