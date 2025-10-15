import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/repository/i_members_repository.dart';

part 'get_members_state.dart';

class GetMembersCubit extends Cubit<GetMembersState> {
  GetMembersCubit(this._membersRepository) : super(GetMembersInitial());
  final IMembersRepository _membersRepository;
  Future<void> getMembers() async {
    emit(GetMembersLoading());
    final response =  _membersRepository.members;
   emit(GetMembersSuccess(response));
  }


}
