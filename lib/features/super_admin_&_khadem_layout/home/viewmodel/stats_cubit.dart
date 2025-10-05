import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/home/model/stats_model.dart';

import '../repository/i_home_repository.dart';

part 'stats_state.dart';

class StatsCubit extends Cubit<StatsState> {
  final IHomeRepository _homeRepository;
  StatsCubit(this._homeRepository) : super(StatsInitial());
  Future<void> fetchStats() async {
    emit(StatsLoading());
    final response = await _homeRepository.fetchStats();
    response.fold(
      (error) => emit(StatsFailure(error)),
      (stats) => emit(StatsSuccess(stats)),
    );
  }
}
