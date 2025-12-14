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
      String? notes,
      bool addScore = true}) async {
    print('🔵 [AddAttendanceCubit] Starting bulk add attendance...'); // Debug
    print('🔵 Members count: ${members.length}'); // Debug
    print('🔵 Event: $event'); // Debug
    print('🔵 Date: $date'); // Debug
    print('🔵 Add score: $addScore'); // Debug

    emit(AddAttendanceLoading());

    final result = await _attendanceRepository.bulkAddAttendance(
        members: members,
        event: event,
        date: date,
        notes: notes,
        addScore: addScore);

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

  Future<void> bulkUpdateAttendance({
    required List<String> attendanceIds,
    String? event,
    DateTime? date,
    String? notes,
    bool impactScore = false,
    bool? shouldAddScore,
  }) async {
    print(
        '🔵 [AddAttendanceCubit] Starting bulk update attendance...'); // Debug
    print('🔵 Attendance IDs count: ${attendanceIds.length}'); // Debug
    print('🔵 Event: $event'); // Debug
    print('🔵 Date: $date'); // Debug

    emit(AddAttendanceLoading());

    final result = await _attendanceRepository.bulkUpdateAttendance(
      attendanceIds: attendanceIds,
      event: event,
      date: date,
      notes: notes,
      impactScore: impactScore,
      shouldAddScore: shouldAddScore,
    );

    result.fold(
      (error) {
        print('❌ [AddAttendanceCubit] Update failed: $error'); // Debug
        emit(AddAttendanceFailure(error));
      },
      (_) {
        print('✅ [AddAttendanceCubit] Update success!'); // Debug
        emit(AddAttendanceSuccess());
      },
    );
  }

}
