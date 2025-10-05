part of 'get_members_cubit.dart';

@immutable
sealed class GetMembersState {}

final class GetMembersInitial extends GetMembersState {}

final class GetMembersLoading extends GetMembersState {}

final class GetMembersSuccess extends GetMembersState {
  final List<UserModel> members;

  GetMembersSuccess(this.members);
}

final class GetMembersFailure extends GetMembersState {
  final String errorMessage;

  GetMembersFailure(this.errorMessage);
}
