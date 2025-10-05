import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/attendance_model.dart';
import '../repository/i_attendance_repository.dart';

part 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  AttendanceCubit(this._attendanceRepository) : super(AttendanceInitial());
  final IAttendanceRepository _attendanceRepository;
  Future<void> fetchAttendance() async {
    emit(AttendanceLoading());
    final result = await _attendanceRepository.fetchAttendance();
    result.fold(
      (failure) => emit(AttendanceFailure(failure)),
      (attendance) => emit(AttendanceSuccess(attendance)),
    );
  }
}
