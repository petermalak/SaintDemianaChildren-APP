part of 'get_aftekad_cubit.dart';

@immutable
sealed class GetAftekadState {}

final class GetAftekadInitial extends GetAftekadState {}

final class GetAftekadLoading extends GetAftekadState {}

final class GetAftekadSuccess extends GetAftekadState {
  GetAftekadSuccess(this.aftekad, {this.makhdoumsMissedFridays});
  final List<AftekadModel> aftekad;
  final Map<String, int>? makhdoumsMissedFridays;
}

final class GetAftekadFailure extends GetAftekadState {
  GetAftekadFailure(this.errorMessage);
  final String errorMessage;
}
