part of 'add_class_cubit.dart';

@immutable
sealed class AddClassState {}

final class AddClassInitial extends AddClassState {}

final class AddClassLoading extends AddClassState {}

final class AddClassSuccess extends AddClassState {}

final class AddClassFailure extends AddClassState {
  final String errorMessage;
  AddClassFailure(this.errorMessage);
}
