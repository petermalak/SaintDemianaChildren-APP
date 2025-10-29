import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

/// Centralized data refresh manager
/// Follows Single Responsibility Principle - only manages refresh events
///
/// This cubit acts as an event bus for data refresh events.
/// Other cubits can listen to this and refresh their data when needed.
class DataRefreshCubit extends Cubit<DataRefreshState> {
  DataRefreshCubit() : super(DataRefreshState.initial());

  /// Trigger refresh for all data
  void refreshAll() {
    print('🔄 [DataRefreshCubit] Refresh ALL triggered');
    emit(DataRefreshState(
      timestamp: DateTime.now(),
      refreshTypes: {RefreshType.all},
    ));
  }

  /// Trigger refresh for attendance data only
  void refreshAttendance() {
    print('🔄 [DataRefreshCubit] Refresh ATTENDANCE triggered');
    emit(DataRefreshState(
      timestamp: DateTime.now(),
      refreshTypes: {RefreshType.attendance},
    ));
  }

  /// Trigger refresh for eftekad data only
  void refreshEftekad() {
    print('🔄 [DataRefreshCubit] Refresh EFTEKAD triggered');
    emit(DataRefreshState(
      timestamp: DateTime.now(),
      refreshTypes: {RefreshType.eftekad},
    ));
  }

  /// Trigger refresh for stats data only
  void refreshStats() {
    print('🔄 [DataRefreshCubit] Refresh STATS triggered');
    emit(DataRefreshState(
      timestamp: DateTime.now(),
      refreshTypes: {RefreshType.stats},
    ));
  }

  /// Trigger refresh for members/users data
  void refreshMembers() {
    print('🔄 [DataRefreshCubit] Refresh MEMBERS triggered');
    emit(DataRefreshState(
      timestamp: DateTime.now(),
      refreshTypes: {RefreshType.members},
    ));
  }

  /// Trigger multiple specific refreshes at once
  void refreshMultiple(Set<RefreshType> types) {
    print('🔄 [DataRefreshCubit] Refresh MULTIPLE triggered: $types');
    emit(DataRefreshState(
      timestamp: DateTime.now(),
      refreshTypes: types,
    ));
  }
}

/// Types of data that can be refreshed
enum RefreshType {
  all,
  attendance,
  eftekad,
  stats,
  members,
  classes,
}

/// State representing a refresh event
class DataRefreshState extends Equatable {
  final DateTime timestamp;
  final Set<RefreshType> refreshTypes;

  const DataRefreshState({
    required this.timestamp,
    required this.refreshTypes,
  });

  DataRefreshState.initial()
      : timestamp = DateTime(2000),
        refreshTypes = const {RefreshType.all};

  /// Check if this refresh should trigger a specific type
  bool shouldRefresh(RefreshType type) {
    return refreshTypes.contains(RefreshType.all) ||
        refreshTypes.contains(type);
  }

  @override
  List<Object?> get props => [timestamp, refreshTypes];
}
