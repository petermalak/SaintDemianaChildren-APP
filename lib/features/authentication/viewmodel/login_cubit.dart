import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/authentication/repository/i_authentication_repository.dart';

import '../model/user_model.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._authenticationRepository) : super(LoginInitial());
  final IAuthenticationRepository _authenticationRepository;

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
}
