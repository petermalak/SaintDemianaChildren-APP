part of 'stats_cubit.dart';

@immutable
sealed class StatsState {}

final class StatsInitial extends StatsState {}

final class StatsLoading extends StatsState {}

final class StatsFailure extends StatsState {
  final String errorMessage;

  StatsFailure(this.errorMessage);
}

final class StatsSuccess extends StatsState {
  final StatsModel stats;

  StatsSuccess(this.stats);
}
