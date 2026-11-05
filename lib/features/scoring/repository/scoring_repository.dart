import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:saint_demiana_children/core/constants/api_endpoints.dart';
import 'package:saint_demiana_children/core/services/interface/i_api_service.dart';
import '../model/scoring_models.dart';
import 'i_scoring_repository.dart';

class ScoringRepository implements IScoringRepository {
  final IApiService _apiService;

  ScoringRepository(this._apiService);

  @override
  Future<Either<String, ScoringConfigModel>> getConfig(String? classId) async {
    try {
      final endpoint = classId != null
          ? '${ApiEndpoints.scoringConfig}/$classId'
          : ApiEndpoints.scoringConfig;

      final response = await _apiService.get(path: endpoint);

      if (response.data['success'] == true) {
        return right(ScoringConfigModel.fromJson(response.data['data']));
      } else {
        return left(response.data['message'] ?? 'Failed to get configuration');
      }
    } on DioException catch (e) {
      return left(e.response?.data['message'] ?? 'Failed to get configuration');
    } catch (e) {
      return left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, ScoringConfigModel>> updateSystemName(
    String? classId,
    String newName,
  ) async {
    try {
      final endpoint = classId != null
          ? '${ApiEndpoints.scoringConfig}/$classId/name'
          : '${ApiEndpoints.scoringConfig}/name';

      final response = await _apiService.put(
        path: endpoint,
        body: {'systemName': newName},
      );

      if (response.data['success'] == true) {
        return right(ScoringConfigModel.fromJson(response.data['data']));
      } else {
        return left(response.data['message'] ?? 'Failed to update system name');
      }
    } on DioException catch (e) {
      return left(
        e.response?.data['message'] ?? 'Failed to update system name',
      );
    } catch (e) {
      return left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, ScoringConfigModel>> updateAttendancePoints(
    String? classId,
    Map<String, int> pointsConfig,
  ) async {
    try {
      final endpoint = classId != null
          ? '${ApiEndpoints.scoringConfig}/$classId/attendance-points'
          : '${ApiEndpoints.scoringConfig}/attendance-points';

      final response = await _apiService.put(
        path: endpoint,
        body: pointsConfig,
      );

      if (response.data['success'] == true) {
        return right(ScoringConfigModel.fromJson(response.data['data']));
      } else {
        return left(
          response.data['message'] ?? 'Failed to update attendance points',
        );
      }
    } on DioException catch (e) {
      return left(
        e.response?.data['message'] ?? 'Failed to update attendance points',
      );
    } catch (e) {
      return left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, ScoringConfigModel>> toggleScoring(
    String classId,
    bool enabled,
  ) async {
    try {
      final response = await _apiService.put(
        path: '${ApiEndpoints.scoringConfig}/$classId/toggle',
        body: {'enabled': enabled},
      );

      if (response.data['success'] == true) {
        return right(ScoringConfigModel.fromJson(response.data['data']));
      } else {
        return left(response.data['message'] ?? 'Failed to toggle scoring');
      }
    } on DioException catch (e) {
      return left(e.response?.data['message'] ?? 'Failed to toggle scoring');
    } catch (e) {
      return left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, List<ScoringTierModel>>> getTiers(
    String? classId,
  ) async {
    try {
      final endpoint = classId != null
          ? '${ApiEndpoints.scoringTiers}$classId'
          : ApiEndpoints.scoringTiers;

      final response = await _apiService.get(path: endpoint);

      if (response.data['success'] == true) {
        final tiers = (response.data['data'] as List)
            .map((tier) => ScoringTierModel.fromJson(tier))
            .toList();
        return right(tiers);
      } else {
        return left(response.data['message'] ?? 'Failed to get tiers');
      }
    } on DioException catch (e) {
      return left(e.response?.data['message'] ?? 'Failed to get tiers');
    } catch (e) {
      return left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, ScoringTierModel>> createTier(
    String? classId,
    Map<String, dynamic> tierData,
  ) async {
    try {
      final endpoint = classId != null
          ? '${ApiEndpoints.scoringTiers}$classId'
          : ApiEndpoints.scoringTiers;

      final response = await _apiService.post(path: endpoint, body: tierData);

      if (response.data['success'] == true) {
        return right(ScoringTierModel.fromJson(response.data['data']));
      } else {
        return left(response.data['message'] ?? 'Failed to create tier');
      }
    } on DioException catch (e) {
      return left(e.response?.data['message'] ?? 'Failed to create tier');
    } catch (e) {
      return left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, ScoringTierModel>> updateTier(
    String tierId,
    Map<String, dynamic> tierData,
  ) async {
    try {
      final response = await _apiService.put(
        path: '${ApiEndpoints.scoringTierById}$tierId',
        body: tierData,
      );

      if (response.data['success'] == true) {
        return right(ScoringTierModel.fromJson(response.data['data']));
      } else {
        return left(response.data['message'] ?? 'Failed to update tier');
      }
    } on DioException catch (e) {
      return left(e.response?.data['message'] ?? 'Failed to update tier');
    } catch (e) {
      return left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, void>> deleteTier(String tierId) async {
    try {
      final response = await _apiService.delete(
        path: '${ApiEndpoints.scoringTierById}$tierId',
      );

      if (response.data['success'] == true) {
        return right(null);
      } else {
        return left(response.data['message'] ?? 'Failed to delete tier');
      }
    } on DioException catch (e) {
      return left(e.response?.data['message'] ?? 'Failed to delete tier');
    } catch (e) {
      return left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, List<ScoreDefinitionModel>>>
      getScoreDefinitions() async {
    try {
      final response =
          await _apiService.get(path: ApiEndpoints.scoreDefinitions);

      if (response.data['success'] == true) {
        final definitions = (response.data['data'] as List)
            .map((json) => ScoreDefinitionModel.fromJson(json))
            .toList();
        definitions.sort((a, b) => a.name.compareTo(b.name));
        return right(definitions);
      } else {
        return left(
          response.data['message'] ?? 'Failed to load score definitions',
        );
      }
    } on DioException catch (e) {
      return left(
        e.response?.data['message'] ?? 'Failed to load score definitions',
      );
    } catch (e) {
      return left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, ScoreDefinitionModel>> createScoreDefinition(
    Map<String, dynamic> definitionData,
  ) async {
    try {
      final response = await _apiService.post(
        path: ApiEndpoints.scoreDefinitions,
        body: definitionData,
      );

      if (response.data['success'] == true) {
        return right(ScoreDefinitionModel.fromJson(response.data['data']));
      } else {
        return left(
          response.data['message'] ?? 'Failed to create score definition',
        );
      }
    } on DioException catch (e) {
      return left(
        e.response?.data['message'] ?? 'Failed to create score definition',
      );
    } catch (e) {
      return left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, ScoreDefinitionModel>> updateScoreDefinition(
    String definitionId,
    Map<String, dynamic> definitionData,
  ) async {
    try {
      final response = await _apiService.put(
        path: ApiEndpoints.scoreDefinitionById(definitionId),
        body: definitionData,
      );

      if (response.data['success'] == true) {
        return right(ScoreDefinitionModel.fromJson(response.data['data']));
      } else {
        return left(
          response.data['message'] ?? 'Failed to update score definition',
        );
      }
    } on DioException catch (e) {
      return left(
        e.response?.data['message'] ?? 'Failed to update score definition',
      );
    } catch (e) {
      return left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, ScoringConfigModel>> assignScoreDefinitionToClass(
    String classId,
    String definitionId,
  ) async {
    try {
      final response = await _apiService.put(
        path: ApiEndpoints.scoringClassScore(classId),
        body: {'scoreDefinitionId': definitionId},
      );

      if (response.data['success'] == true) {
        return right(ScoringConfigModel.fromJson(response.data['data']));
      } else {
        return left(
          response.data['message'] ?? 'Failed to assign score definition',
        );
      }
    } on DioException catch (e) {
      return left(
        e.response?.data['message'] ?? 'Failed to assign score definition',
      );
    } catch (e) {
      return left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, UserScoreModel>> getUserScore(
    String userId,
    String classId,
  ) async {
    try {
      final response = await _apiService.get(
        path: '${ApiEndpoints.scoringUsers}$userId/classes/$classId/score',
      );

      if (response.data['success'] == true) {
        return right(UserScoreModel.fromJson(response.data['data']));
      } else {
        return left(response.data['message'] ?? 'Failed to get user score');
      }
    } on DioException catch (e) {
      return left(e.response?.data['message'] ?? 'Failed to get user score');
    } catch (e) {
      return left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, List<UserScoreModel>>> getMyScores() async {
    try {
      final response = await _apiService.get(path: ApiEndpoints.myScores);

      if (response.data['success'] == true) {
        final scores = (response.data['data'] as List)
            .map((score) => UserScoreModel.fromJson(score))
            .toList();
        return right(scores);
      } else {
        return left(response.data['message'] ?? 'Failed to get scores');
      }
    } on DioException catch (e) {
      return left(e.response?.data['message'] ?? 'Failed to get scores');
    } catch (e) {
      return left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, Map<String, dynamic>>> addPoints(
    String userId,
    String classId,
    int points,
    String? reason,
  ) async {
    try {
      final response = await _apiService.post(
        path: '${ApiEndpoints.scoringUsers}$userId/classes/$classId/add-points',
        body: {'points': points, 'reason': reason},
      );

      if (response.data['success'] == true) {
        return right(response.data);
      } else {
        return left(response.data['message'] ?? 'Failed to add points');
      }
    } on DioException catch (e) {
      return left(e.response?.data['message'] ?? 'Failed to add points');
    } catch (e) {
      return left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, Map<String, dynamic>>> removePoints(
    String userId,
    String classId,
    int points,
    String? reason,
  ) async {
    try {
      final response = await _apiService.post(
        path:
            '${ApiEndpoints.scoringUsers}$userId/classes/$classId/remove-points',
        body: {'points': points, 'reason': reason},
      );

      if (response.data['success'] == true) {
        return right(response.data);
      } else {
        return left(response.data['message'] ?? 'Failed to remove points');
      }
    } on DioException catch (e) {
      return left(e.response?.data['message'] ?? 'Failed to remove points');
    } catch (e) {
      return left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, List<LeaderboardEntryModel>>> getLeaderboard(
    String classId, {
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await _apiService.get(
        path:
            '${ApiEndpoints.scoringClasses}$classId/leaderboard?limit=$limit&offset=$offset',
      );

      if (response.data['success'] == true) {
        final leaderboard = (response.data['data'] as List)
            .map((entry) => LeaderboardEntryModel.fromJson(entry))
            .toList();
        return right(leaderboard);
      } else {
        return left(response.data['message'] ?? 'Failed to get leaderboard');
      }
    } on DioException catch (e) {
      return left(e.response?.data['message'] ?? 'Failed to get leaderboard');
    } catch (e) {
      return left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, Map<String, dynamic>>> getUserRank(
    String userId,
    String classId,
  ) async {
    try {
      final response = await _apiService.get(
        path: '${ApiEndpoints.scoringUsers}$userId/classes/$classId/rank',
      );

      if (response.data['success'] == true) {
        return right(response.data['data']);
      } else {
        return left(response.data['message'] ?? 'Failed to get user rank');
      }
    } on DioException catch (e) {
      return left(e.response?.data['message'] ?? 'Failed to get user rank');
    } catch (e) {
      return left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, List<ScoreTransactionModel>>> getTransactionHistory(
    String userId,
    String classId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiService.get(
        path:
            '${ApiEndpoints.scoringUsers}$userId/classes/$classId/transactions?limit=$limit&offset=$offset',
      );

      if (response.data['success'] == true) {
        final transactions = (response.data['data'] as List)
            .map((transaction) => ScoreTransactionModel.fromJson(transaction))
            .toList();
        return right(transactions);
      } else {
        return left(
          response.data['message'] ?? 'Failed to get transaction history',
        );
      }
    } on DioException catch (e) {
      return left(
        e.response?.data['message'] ?? 'Failed to get transaction history',
      );
    } catch (e) {
      return left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, List<ScoreTransactionModel>>> getMyTransactions({
    String? classId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      String queryParams = '?limit=$limit&offset=$offset';
      if (classId != null) {
        queryParams += '&classId=$classId';
      }

      final response = await _apiService.get(
        path: '${ApiEndpoints.myTransactions}$queryParams',
      );

      if (response.data['success'] == true) {
        final transactions = (response.data['data'] as List)
            .map((transaction) => ScoreTransactionModel.fromJson(transaction))
            .toList();
        return right(transactions);
      } else {
        return left(response.data['message'] ?? 'Failed to get transactions');
      }
    } on DioException catch (e) {
      return left(e.response?.data['message'] ?? 'Failed to get transactions');
    } catch (e) {
      return left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, ScoreStats>> getUserStats(
    String userId,
    String classId,
  ) async {
    try {
      final response = await _apiService.get(
        path: '${ApiEndpoints.scoringUsers}$userId/classes/$classId/stats',
      );

      if (response.data['success'] == true) {
        return right(ScoreStats.fromJson(response.data['data']));
      } else {
        return left(response.data['message'] ?? 'Failed to get user stats');
      }
    } on DioException catch (e) {
      return left(e.response?.data['message'] ?? 'Failed to get user stats');
    } catch (e) {
      return left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, ScoreStats>> getClassStats(String classId) async {
    try {
      final response = await _apiService.get(
        path: '${ApiEndpoints.scoringClasses}$classId/stats',
      );

      if (response.data['success'] == true) {
        return right(ScoreStats.fromJson(response.data['data']));
      } else {
        return left(response.data['message'] ?? 'Failed to get class stats');
      }
    } on DioException catch (e) {
      return left(e.response?.data['message'] ?? 'Failed to get class stats');
    } catch (e) {
      return left('An unexpected error occurred: $e');
    }
  }
}
