part of 'add_attendance_cubit.dart';

@immutable
sealed class AddAttendanceState {}

final class AddAttendanceInitial extends AddAttendanceState {}

final class AddAttendanceLoading extends AddAttendanceState {}

final class AddAttendanceSuccess extends AddAttendanceState {}

final class AddAttendanceFailure extends AddAttendanceState {
  AddAttendanceFailure(this.errorMessage);
  final String errorMessage;
}
