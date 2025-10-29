import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/authentication/repository/i_authentication_repository.dart';
import 'package:saint_demiana_children/features/authentication/viewmodel/change_password_state.dart';

/// Cubit for managing change password state
/// Follows SOLID principles and clean architecture
class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  final IAuthenticationRepository _authRepository;

  ChangePasswordCubit(this._authRepository) : super(ChangePasswordInitial());

  /// Change user password
  /// Validates inputs and calls repository method
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    // Validate inputs
    if (currentPassword.isEmpty) {
      emit(ChangePasswordFailure(
        errorMessage: 'كلمة المرور الحالية مطلوبة',
      ));
      return;
    }

    if (newPassword.isEmpty) {
      emit(ChangePasswordFailure(
        errorMessage: 'كلمة المرور الجديدة مطلوبة',
      ));
      return;
    }

    if (newPassword.length < 6) {
      emit(ChangePasswordFailure(
        errorMessage: 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
      ));
      return;
    }

    if (confirmPassword.isEmpty) {
      emit(ChangePasswordFailure(
        errorMessage: 'تأكيد كلمة المرور مطلوب',
      ));
      return;
    }

    if (newPassword != confirmPassword) {
      emit(ChangePasswordFailure(
        errorMessage: 'كلمة المرور الجديدة وتأكيد كلمة المرور غير متطابقين',
      ));
      return;
    }

    if (currentPassword == newPassword) {
      emit(ChangePasswordFailure(
        errorMessage: 'كلمة المرور الجديدة يجب أن تكون مختلفة عن الحالية',
      ));
      return;
    }

    emit(ChangePasswordLoading());

    final result = await _authRepository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    result.fold(
      (error) => emit(ChangePasswordFailure(errorMessage: error)),
      (_) => emit(ChangePasswordSuccess()),
    );
  }

  /// Reset state to initial
  void reset() {
    emit(ChangePasswordInitial());
  }
}
