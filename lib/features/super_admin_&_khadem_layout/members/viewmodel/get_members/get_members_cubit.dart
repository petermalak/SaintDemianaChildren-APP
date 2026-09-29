import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/repository/i_members_repository.dart';

import '../../../../../core/di/service_locator.dart';
import '../../../../profile/repository/i_profile_repository.dart';

part 'get_members_state.dart';

class GetMembersCubit extends Cubit<GetMembersState> {
  GetMembersCubit(this._membersRepository) : super(GetMembersInitial());
  final IMembersRepository _membersRepository;

  /// Shows the already loaded members immediately, and fetches from the server
  /// when nothing is cached yet or the user pulled to refresh.
  Future<void> getMembers({bool forceRefresh = false}) async {
    final cached = _membersRepository.members;
    if (cached.isNotEmpty) {
      emit(GetMembersSuccess(List.of(cached)));
    } else {
      emit(GetMembersLoading());
    }

    if (cached.isNotEmpty && !forceRefresh) return;

    final isSuperAdmin =
        sl<IProfileRepository>().user?.role == UserRole.superAdmin;
    final result = await _membersRepository.fetchMembers(isSuperAdmin);
    if (isClosed) return;

    result.fold(
      (error) {
        // Keep showing what we have; only report when there is nothing to show.
        if (_membersRepository.members.isEmpty) emit(GetMembersFailure(error));
      },
      (members) => emit(GetMembersSuccess(List.of(members))),
    );
  }
}
