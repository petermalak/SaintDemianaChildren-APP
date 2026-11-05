import 'package:dartz/dartz.dart';
import '../model/scoring_models.dart';

abstract class IScoringRepository {
  // Configuration
  Future<Either<String, ScoringConfigModel>> getConfig(String? classId);
  Future<Either<String, ScoringConfigModel>> updateSystemName(
    String? classId,
    String newName,
  );
  Future<Either<String, ScoringConfigModel>> updateAttendancePoints(
    String? classId,
    Map<String, int> pointsConfig,
  );
  Future<Either<String, ScoringConfigModel>> toggleScoring(
    String classId,
    bool enabled,
  );

  // Tiers
  Future<Either<String, List<ScoringTierModel>>> getTiers(String? classId);
  Future<Either<String, ScoringTierModel>> createTier(
    String? classId,
    Map<String, dynamic> tierData,
  );
  Future<Either<String, ScoringTierModel>> updateTier(
    String tierId,
    Map<String, dynamic> tierData,
  );
  Future<Either<String, void>> deleteTier(String tierId);

  // Score definitions
  Future<Either<String, List<ScoreDefinitionModel>>> getScoreDefinitions();
  Future<Either<String, ScoreDefinitionModel>> createScoreDefinition(
    Map<String, dynamic> definitionData,
  );
  Future<Either<String, ScoreDefinitionModel>> updateScoreDefinition(
    String definitionId,
    Map<String, dynamic> definitionData,
  );
  Future<Either<String, ScoringConfigModel>> assignScoreDefinitionToClass(
    String classId,
    String definitionId,
  );

  // User Scores
  Future<Either<String, UserScoreModel>> getUserScore(
    String userId,
    String classId,
  );
  Future<Either<String, List<UserScoreModel>>> getMyScores();
  Future<Either<String, Map<String, dynamic>>> addPoints(
    String userId,
    String classId,
    int points,
    String? reason,
  );
  Future<Either<String, Map<String, dynamic>>> removePoints(
    String userId,
    String classId,
    int points,
    String? reason,
  );

  // Leaderboard
  Future<Either<String, List<LeaderboardEntryModel>>> getLeaderboard(
    String classId, {
    int limit = 10,
    int offset = 0,
  });
  Future<Either<String, Map<String, dynamic>>> getUserRank(
    String userId,
    String classId,
  );

  // Transactions
  Future<Either<String, List<ScoreTransactionModel>>> getTransactionHistory(
    String userId,
    String classId, {
    int limit = 50,
    int offset = 0,
  });
  Future<Either<String, List<ScoreTransactionModel>>> getMyTransactions({
    String? classId,
    int limit = 50,
    int offset = 0,
  });

  // Statistics
  Future<Either<String, ScoreStats>> getUserStats(
    String userId,
    String classId,
  );
  Future<Either<String, ScoreStats>> getClassStats(String classId);
}
