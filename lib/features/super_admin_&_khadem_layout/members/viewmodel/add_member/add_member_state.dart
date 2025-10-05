part of 'add_member_cubit.dart';

@immutable
sealed class AddMemberState {}

final class AddMemberInitial extends AddMemberState {}

final class AddMemberLoading extends AddMemberState {}

final class AddMemberSuccess extends AddMemberState {}

final class AddMemberFailure extends AddMemberState {
  final String errorMessage;

  AddMemberFailure(this.errorMessage);
}
