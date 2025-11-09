import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/home/model/stats_model.dart';

import '../../../../core/services/data_refresh_cubit.dart';
import '../repository/i_home_repository.dart';

part 'stats_state.dart';

class StatsCubit extends Cubit<StatsState> {
  final IHomeRepository _homeRepository;
  final DataRefreshCubit? _refreshCubit;
  StreamSubscription? _refreshSubscription;

  StatsCubit(this._homeRepository, [this._refreshCubit])
      : super(StatsInitial()) {
    // Listen to refresh events
    _refreshSubscription = _refreshCubit?.stream.listen((refreshState) {
      if (refreshState.shouldRefresh(RefreshType.stats) ||
          refreshState.shouldRefresh(RefreshType.all)) {
        print('📊 [StatsCubit] Refresh triggered');
        fetchStats();
      }
    });
  }

  Future<void> fetchStats({String? classId}) async {
    emit(StatsLoading());
    final response = await _homeRepository.fetchStats(classId: classId);
    response.fold(
      (error) => emit(StatsFailure(error)),
      (stats) => emit(StatsSuccess(stats)),
    );
  }

  @override
  Future<void> close() {
    _refreshSubscription?.cancel();
    return super.close();
  }
}
