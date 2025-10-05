part of 'aftekad_cubit.dart';

@immutable
sealed class AftekadState {}

final class AftekadInitial extends AftekadState {}

final class AftekadLoading extends AftekadState {}

final class AftekadSuccess extends AftekadState {
  AftekadSuccess(this.aftekad);
  final List aftekad;
}

final class AftekadFailure extends AftekadState {
  AftekadFailure(this.errorMessage);
  final String errorMessage;
}
