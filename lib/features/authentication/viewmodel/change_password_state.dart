/// Base state for change password feature
abstract class ChangePasswordState {}

/// Initial state
class ChangePasswordInitial extends ChangePasswordState {}

/// Loading state while changing password
class ChangePasswordLoading extends ChangePasswordState {}

/// Success state after password change
class ChangePasswordSuccess extends ChangePasswordState {
  final String message;

  ChangePasswordSuccess({this.message = 'تم تغيير كلمة المرور بنجاح'});
}

/// Failure state when password change fails
class ChangePasswordFailure extends ChangePasswordState {
  final String errorMessage;

  ChangePasswordFailure({required this.errorMessage});
}
