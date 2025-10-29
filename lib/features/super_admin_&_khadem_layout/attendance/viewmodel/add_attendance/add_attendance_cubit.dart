import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/attendance/repository/i_attendance_repository.dart';

part 'add_attendance_state.dart';

class AddAttendanceCubit extends Cubit<AddAttendanceState> {
  AddAttendanceCubit(this._attendanceRepository)
      : super(AddAttendanceInitial());
  final IAttendanceRepository _attendanceRepository;

  Future<void> bulkAddAttendance(
      {required List<UserModel> members,
      required String event,
      required DateTime date,
      String? notes}) async {
    print('🔵 [AddAttendanceCubit] Starting bulk add attendance...'); // Debug
    print('🔵 Members count: ${members.length}'); // Debug
    print('🔵 Event: $event'); // Debug
    print('🔵 Date: $date'); // Debug

    emit(AddAttendanceLoading());

    final result = await _attendanceRepository.bulkAddAttendance(
        members: members, event: event, date: date, notes: notes);

    result.fold(
      (error) {
        print('❌ [AddAttendanceCubit] Failed: $error'); // Debug
        emit(AddAttendanceFailure(error));
      },
      (_) {
        print('✅ [AddAttendanceCubit] Success!'); // Debug
        emit(AddAttendanceSuccess());
      },
    );
  }
}
