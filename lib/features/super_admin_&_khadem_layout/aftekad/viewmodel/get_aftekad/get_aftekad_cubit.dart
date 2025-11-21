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
  String? _lastClassId;
  String? _lastKhademName;
  String? _lastKhademScope;
  Map<String, int>? _makhdoumsMissedFridays;

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
        // Use Friday date from refresh state if provided, otherwise use last Friday date
        final fridayDateToUse = refreshState.fridayDate ?? _lastFridayDate;
        if (fridayDateToUse != null) {
          print(
              '🔄 [GetAftekadCubit] Reloading data: date=$fridayDateToUse, khadem=$_lastKhademId, class=$_lastClassId');
          getAftekad(
            fridayDateToUse,
            khademId: _lastKhademId,
            classId: _lastClassId,
            khademName: _lastKhademName,
            khademScope: _lastKhademScope,
          );
        } else {
          print(
              '⚠️ [GetAftekadCubit] Cannot refresh - missing date or khademId');
        }
      }
    });
  }

  Future<void> getAftekad(
    String fridayDate, {
    String? khademId,
    String? classId,
    String? khademName,
    String? khademScope,
  }) async {
    final scopeToUse = khademScope ?? _lastKhademScope;
    print(
        '📥 [GetAftekadCubit] Fetching aftekad: date=$fridayDate, khadem=$khademId, class=$classId, khademName=$khademName, scope=$scopeToUse');
    _lastFridayDate = fridayDate;
    _lastKhademId = khademId;
    _lastClassId = classId;
    _lastKhademName = khademName;
    _lastKhademScope = scopeToUse;

    emit(GetAftekadLoading());
    final result = await _aftekadRepository.getAftekadByWeek(
      fridayDate,
      khademId: khademId,
      classId: classId,
      khademName: khademName,
      khademScope: scopeToUse,
    );
    result.fold(
      (failure) {
        print('❌ [GetAftekadCubit] Fetch failed: $failure');
        _makhdoumsMissedFridays = null;
        emit(GetAftekadFailure(failure));
      },
      (aftekad) {
        // Get makhdoumsMissedFridays from repository
        _makhdoumsMissedFridays = _aftekadRepository.lastMakhdoumsMissedFridays;
        print('✅ [GetAftekadCubit] Fetch successful: ${aftekad.length} items');
        print(
            '📊 [GetAftekadCubit] Makhdoums missed Fridays: $_makhdoumsMissedFridays');
        emit(GetAftekadSuccess(aftekad,
            makhdoumsMissedFridays: _makhdoumsMissedFridays));
      },
    );
  }

  // Getter for makhdoumsMissedFridays
  Map<String, int>? get makhdoumsMissedFridays => _makhdoumsMissedFridays;

  void updateKhademScope(String? scope) {
    _lastKhademScope = scope;
  }

  @override
  Future<void> close() {
    _refreshSubscription?.cancel();
    return super.close();
  }
}
