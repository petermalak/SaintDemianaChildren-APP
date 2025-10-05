import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  AttendanceCubit() : super(AttendanceInitial());

  Future<void> fetchAttendance() async {
    emit(AttendanceLoading());
  }
}
