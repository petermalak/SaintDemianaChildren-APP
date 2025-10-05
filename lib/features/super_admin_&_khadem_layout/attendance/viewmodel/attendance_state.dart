part of 'attendance_cubit.dart';

@immutable
sealed class AttendanceState {}

final class AttendanceInitial extends AttendanceState {}

final class AttendanceLoading extends AttendanceState {}

final class AttendanceSuccess extends AttendanceState {
  AttendanceSuccess(this.attendance);
  final AttendanceModel attendance;
}

final class AttendanceFailure extends AttendanceState {
  AttendanceFailure(this.errorMessage);
  final String errorMessage;
}
