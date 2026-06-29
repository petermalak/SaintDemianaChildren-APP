import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../super_admin_&_khadem_layout/attendance/model/attendance_model.dart';
import '../repository/i_attendance_repository.dart';

part 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  final IAttendanceRepository _attendanceRepository;

  AttendanceCubit(this._attendanceRepository) : super(AttendanceInitial());

  Future<void> fetchAttendance({String? classId}) async {
    if (isClosed) return;
    emit(AttendanceLoading());

    final result = await _attendanceRepository.fetchAttendance(classId: classId);

    if (isClosed) return;
    result.fold(
      (error) => emit(AttendanceFailure(error)),
      (attendanceModel) => emit(AttendanceSuccess(attendanceModel)),
    );
  }
}
