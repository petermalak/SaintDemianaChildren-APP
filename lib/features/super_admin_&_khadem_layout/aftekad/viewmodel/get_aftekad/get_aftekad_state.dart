part of 'get_aftekad_cubit.dart';

@immutable
sealed class GetAftekadState {}

final class GetAftekadInitial extends GetAftekadState {}

final class GetAftekadLoading extends GetAftekadState {}

final class GetAftekadSuccess extends GetAftekadState {
  GetAftekadSuccess(this.aftekad);
  final List<AftekadModel> aftekad;
}

final class GetAftekadFailure extends GetAftekadState {
  GetAftekadFailure(this.errorMessage);
  final String errorMessage;
}
