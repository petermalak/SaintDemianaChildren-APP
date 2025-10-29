import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';
import 'package:saint_demiana_children/features/profile/repository/i_profile_repository.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._profileRepository) : super(ProfileInitial());
  final IProfileRepository _profileRepository;

  Future<void> updateProfile(UserModel user) async {
    emit(ProfileLoading());
    final result = await _profileRepository.updateProfile(user);
    result.fold(
      (failure) => emit(ProfileFailure(failure)),
      (_) => emit(ProfileSuccess()),
    );
  }
}
