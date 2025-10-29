part of 'add_aftekad_cubit.dart';

@immutable
sealed class AddAftekadState {}

final class AddAftekadInitial extends AddAftekadState {}

final class AddAftekadLoading extends AddAftekadState {}

final class AddAftekadSuccess extends AddAftekadState {}

final class AddAftekadFailure extends AddAftekadState {
  AddAftekadFailure(this.errorMessage);
  final String errorMessage;
}
