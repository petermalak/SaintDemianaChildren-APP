import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../model/attendance_model.dart';
import '../../repository/i_attendance_repository.dart';

part 'get_attendance_state.dart';

class GetAttendanceCubit extends Cubit<GetAttendanceState> {
  GetAttendanceCubit(this._attendanceRepository)
      : super(GetAttendanceInitial());
  final IAttendanceRepository _attendanceRepository;
  Future<void> fetchAttendance() async {
    emit(GetAttendanceLoading());
    final result = await _attendanceRepository.fetchAttendance();
    result.fold(
      (failure) => emit(GetAttendanceFailure(failure)),
      (attendance) => emit(GetAttendanceSuccess(attendance)),
    );
  }
}
