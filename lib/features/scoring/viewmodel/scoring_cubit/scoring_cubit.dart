import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../repository/i_scoring_repository.dart';
import '../class_scores_cache.dart';
import 'scoring_state.dart';

class ScoringCubit extends Cubit<ScoringState> {
  final IScoringRepository _scoringRepository;

  ScoringCubit(this._scoringRepository) : super(ScoringInitial());

  // Get user score for a specific class
  Future<void> getUserScore(String userId, String classId) async {
    print(
        '🏆 [ScoringCubit] getUserScore called - userId: $userId, classId: $classId');
    emit(ScoringLoading());
    print('🏆 [ScoringCubit] Emitted ScoringLoading');

    final result = await _scoringRepository.getUserScore(userId, classId);
    print('🏆 [ScoringCubit] Repository returned result');

    result.fold(
      (error) {
        print('❌ [ScoringCubit] Error: $error');
        emit(ScoringError(error));
      },
      (userScore) {
        print('✅ [ScoringCubit] Success - Points: ${userScore.totalPoints}');
        emit(UserScoreLoaded(userScore));
      },
    );
  }

  // Get all scores for the current user
  Future<void> getMyScores() async {
    emit(ScoringLoading());

    final result = await _scoringRepository.getMyScores();

    result.fold(
      (error) => emit(ScoringError(error)),
      (scores) => emit(MyScoresLoaded(scores)),
    );
  }

  // Get leaderboard for a class
  Future<void> getLeaderboard(String classId,
      {int limit = 10, int offset = 0}) async {
    emit(ScoringLoading());

    final result = await _scoringRepository.getLeaderboard(
      classId,
      limit: limit,
      offset: offset,
    );

    result.fold(
      (error) => emit(ScoringError(error)),
      (leaderboard) => emit(LeaderboardLoaded(leaderboard)),
    );
  }

  // Get user rank in class
  Future<void> getUserRank(String userId, String classId) async {
    emit(ScoringLoading());

    final result = await _scoringRepository.getUserRank(userId, classId);

    result.fold(
      (error) => emit(ScoringError(error)),
      (data) => emit(UserRankLoaded(
        rank: data['rank'],
        totalPoints: data['totalPoints'],
        tier: data['tier'] != null ? data['tier'] : null,
      )),
    );
  }

  // Get transaction history
  Future<void> getTransactionHistory(
    String userId,
    String classId, {
    int limit = 50,
    int offset = 0,
  }) async {
    emit(ScoringLoading());

    final result = await _scoringRepository.getTransactionHistory(
      userId,
      classId,
      limit: limit,
      offset: offset,
    );

    result.fold(
      (error) => emit(ScoringError(error)),
      (transactions) => emit(TransactionsLoaded(transactions)),
    );
  }

  // Get my transactions
  Future<void> getMyTransactions({
    String? classId,
    int limit = 50,
    int offset = 0,
  }) async {
    emit(ScoringLoading());

    final result = await _scoringRepository.getMyTransactions(
      classId: classId,
      limit: limit,
      offset: offset,
    );

    result.fold(
      (error) => emit(ScoringError(error)),
      (transactions) => emit(TransactionsLoaded(transactions)),
    );
  }

  // Get user stats
  Future<void> getUserStats(String userId, String classId) async {
    emit(ScoringLoading());

    final result = await _scoringRepository.getUserStats(userId, classId);

    result.fold(
      (error) => emit(ScoringError(error)),
      (stats) => emit(StatsLoaded(stats)),
    );
  }

  // Get class stats
  Future<void> getClassStats(String classId) async {
    emit(ScoringLoading());

    final result = await _scoringRepository.getClassStats(classId);

    result.fold(
      (error) => emit(ScoringError(error)),
      (stats) => emit(StatsLoaded(stats)),
    );
  }

  // Add points manually
  Future<void> addPoints(
    String userId,
    String classId,
    int points,
    String? reason,
  ) async {
    emit(ScoringLoading());

    final result = await _scoringRepository.addPoints(
      userId,
      classId,
      points,
      reason,
    );

    result.fold(
      (error) => emit(ScoringError(error)),
      (data) {
        sl<ClassScoresCache>().invalidate(classId);
        emit(PointsUpdated(
          oldPoints: data['oldPoints'],
          newPoints: data['newPoints'],
          wasAddition: true,
        ));
      },
    );
  }

  // Remove points manually
  Future<void> removePoints(
    String userId,
    String classId,
    int points,
    String? reason,
  ) async {
    emit(ScoringLoading());

    final result = await _scoringRepository.removePoints(
      userId,
      classId,
      points,
      reason,
    );

    result.fold(
      (error) => emit(ScoringError(error)),
      (data) {
        sl<ClassScoresCache>().invalidate(classId);
        emit(PointsUpdated(
          oldPoints: data['oldPoints'],
          newPoints: data['newPoints'],
          wasAddition: false,
        ));
      },
    );
  }

  // Reset state
  void reset() {
    emit(ScoringInitial());
  }
}
