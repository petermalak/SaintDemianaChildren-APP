import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repository/i_scoring_repository.dart';
import 'config_state.dart';

class ConfigCubit extends Cubit<ConfigState> {
  final IScoringRepository _scoringRepository;

  ConfigCubit(this._scoringRepository) : super(ConfigInitial());

  // Get configuration
  Future<void> getConfig(String? classId) async {
    emit(ConfigLoading());

    final result = await _scoringRepository.getConfig(classId);

    result.fold(
      (error) => emit(ConfigError(error)),
      (config) => emit(ConfigLoaded(config)),
    );
  }

  // Update system name
  Future<void> updateSystemName(String? classId, String newName) async {
    emit(ConfigLoading());

    final result = await _scoringRepository.updateSystemName(classId, newName);

    result.fold(
      (error) => emit(ConfigError(error)),
      (config) => emit(ConfigUpdated(config)),
    );
  }

  // Update attendance points
  Future<void> updateAttendancePoints(
    String? classId,
    Map<String, int> pointsConfig,
  ) async {
    emit(ConfigLoading());

    final result = await _scoringRepository.updateAttendancePoints(
      classId,
      pointsConfig,
    );

    result.fold(
      (error) => emit(ConfigError(error)),
      (config) => emit(ConfigUpdated(config)),
    );
  }

  // Toggle scoring
  Future<void> toggleScoring(String classId, bool enabled) async {
    emit(ConfigLoading());

    final result = await _scoringRepository.toggleScoring(classId, enabled);

    result.fold(
      (error) => emit(ConfigError(error)),
      (config) => emit(ConfigUpdated(config)),
    );
  }

  // Get tiers
  Future<void> getTiers(String? classId) async {
    emit(ConfigLoading());

    final result = await _scoringRepository.getTiers(classId);

    result.fold(
      (error) => emit(ConfigError(error)),
      (tiers) => emit(TiersLoaded(tiers)),
    );
  }

  // Create tier
  Future<void> createTier(
      String? classId, Map<String, dynamic> tierData) async {
    emit(ConfigLoading());

    final result = await _scoringRepository.createTier(classId, tierData);

    result.fold(
      (error) => emit(ConfigError(error)),
      (tier) => emit(TierCreated(tier)),
    );
  }

  // Update tier
  Future<void> updateTier(String tierId, Map<String, dynamic> tierData) async {
    emit(ConfigLoading());

    final result = await _scoringRepository.updateTier(tierId, tierData);

    result.fold(
      (error) => emit(ConfigError(error)),
      (tier) => emit(TierUpdated(tier)),
    );
  }

  // Delete tier
  Future<void> deleteTier(String tierId) async {
    emit(ConfigLoading());

    final result = await _scoringRepository.deleteTier(tierId);

    result.fold(
      (error) => emit(ConfigError(error)),
      (_) => emit(const TierDeleted()),
    );
  }

  // Reset state
  void reset() {
    emit(ConfigInitial());
  }
}
