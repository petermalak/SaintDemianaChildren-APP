part of 'attendance_cubit.dart';

@immutable
sealed class AttendanceState {}

final class AttendanceInitial extends AttendanceState {}

final class AttendanceLoading extends AttendanceState {}

final class AttendanceFailure extends AttendanceState {
  final String errorMessage;
  AttendanceFailure(this.errorMessage);
}

final class AttendanceSuccess extends AttendanceState {
  final AttendanceModel attendanceModel;
  AttendanceSuccess(this.attendanceModel);
}
