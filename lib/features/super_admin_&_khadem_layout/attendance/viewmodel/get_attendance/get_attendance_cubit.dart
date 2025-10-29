import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/services/data_refresh_cubit.dart';
import '../../model/attendance_model.dart';
import '../../repository/i_attendance_repository.dart';

part 'get_attendance_state.dart';

class GetAttendanceCubit extends Cubit<GetAttendanceState> {
  final IAttendanceRepository _attendanceRepository;
  final DataRefreshCubit? _refreshCubit;
  StreamSubscription? _refreshSubscription;

  GetAttendanceCubit(this._attendanceRepository, [this._refreshCubit])
      : super(GetAttendanceInitial()) {
    // Listen to refresh events
    _refreshSubscription = _refreshCubit?.stream.listen((refreshState) {
      if (refreshState.shouldRefresh(RefreshType.attendance) ||
          refreshState.shouldRefresh(RefreshType.all)) {
        print('📋 [GetAttendanceCubit] Refresh triggered');
        fetchAttendance();
      }
    });
  }

  Future<void> fetchAttendance() async {
    emit(GetAttendanceLoading());
    final result = await _attendanceRepository.fetchAttendance();
    result.fold(
      (failure) => emit(GetAttendanceFailure(failure)),
      (attendance) => emit(GetAttendanceSuccess(attendance)),
    );
  }

  @override
  Future<void> close() {
    _refreshSubscription?.cancel();
    return super.close();
  }
}
