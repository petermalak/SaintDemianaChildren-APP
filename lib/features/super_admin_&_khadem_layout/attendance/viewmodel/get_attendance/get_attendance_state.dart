part of 'get_attendance_cubit.dart';

@immutable
sealed class GetAttendanceState {}

final class GetAttendanceInitial extends GetAttendanceState {}

final class GetAttendanceLoading extends GetAttendanceState {}

final class GetAttendanceSuccess extends GetAttendanceState {
  GetAttendanceSuccess(this.attendance);
  final AttendanceModel attendance;
}

final class GetAttendanceFailure extends GetAttendanceState {
  GetAttendanceFailure(this.errorMessage);
  final String errorMessage;
}
