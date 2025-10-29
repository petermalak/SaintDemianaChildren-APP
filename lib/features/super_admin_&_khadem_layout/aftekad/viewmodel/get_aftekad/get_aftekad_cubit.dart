import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/model/aftekad_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/repository/i_aftekad_repository.dart';

import '../../../../../core/services/data_refresh_cubit.dart';

part 'get_aftekad_state.dart';

class GetAftekadCubit extends Cubit<GetAftekadState> {
  final IAftekadRepository _aftekadRepository;
  final DataRefreshCubit? _refreshCubit;
  StreamSubscription? _refreshSubscription;
  String? _lastFridayDate;
  String? _lastKhademId;

  GetAftekadCubit(this._aftekadRepository, [this._refreshCubit])
      : super(GetAftekadInitial()) {
    print(
        '🔧 [GetAftekadCubit] Initialized with refreshCubit: ${_refreshCubit != null}');
    // Listen to refresh events
    _refreshSubscription = _refreshCubit?.stream.listen((refreshState) {
      print(
          '🔔 [GetAftekadCubit] Refresh state changed: ${refreshState.refreshTypes}');
      if (refreshState.shouldRefresh(RefreshType.eftekad) ||
          refreshState.shouldRefresh(RefreshType.all)) {
        print('✅ [GetAftekadCubit] Refresh triggered for eftekad!');
        // Re-fetch with last parameters
        if (_lastFridayDate != null && _lastKhademId != null) {
          print(
              '🔄 [GetAftekadCubit] Reloading data: date=$_lastFridayDate, khadem=$_lastKhademId');
          getAftekad(_lastFridayDate!, _lastKhademId!);
        } else {
          print(
              '⚠️ [GetAftekadCubit] Cannot refresh - missing date or khademId');
        }
      }
    });
  }

  Future<void> getAftekad(String fridayDate, String khademId) async {
    print(
        '📥 [GetAftekadCubit] Fetching aftekad: date=$fridayDate, khadem=$khademId');
    _lastFridayDate = fridayDate;
    _lastKhademId = khademId;

    emit(GetAftekadLoading());
    final result =
        await _aftekadRepository.getAftekadByWeek(fridayDate, khademId);
    result.fold(
      (failure) {
        print('❌ [GetAftekadCubit] Fetch failed: $failure');
        emit(GetAftekadFailure(failure));
      },
      (aftekad) {
        print('✅ [GetAftekadCubit] Fetch successful: ${aftekad.length} items');
        emit(GetAftekadSuccess(aftekad));
      },
    );
  }

  @override
  Future<void> close() {
    _refreshSubscription?.cancel();
    return super.close();
  }
}
