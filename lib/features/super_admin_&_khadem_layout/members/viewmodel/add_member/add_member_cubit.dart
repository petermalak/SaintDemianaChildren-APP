import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';

import '../../repository/i_members_repository.dart';

part 'add_member_state.dart';

class AddMemberCubit extends Cubit<AddMemberState> {
  AddMemberCubit(this._membersRepository) : super(AddMemberInitial());
  final IMembersRepository _membersRepository;
  Future<void> addMember(UserModel user) async {
    emit(AddMemberLoading());
    final response = await _membersRepository.addMember(user);
    response.fold(
      (failure) => emit(AddMemberFailure(failure)),
      (success) => emit(AddMemberSuccess()),
    );
  }

  Future<void> updateMemberProfile(UserModel user) async {
    emit(AddMemberLoading());
    final response = await _membersRepository.updateMemberProfile(user);
    response.fold(
      (failure) => emit(AddMemberFailure(failure)),
      (success) => emit(AddMemberSuccess()),
    );
  }
}
