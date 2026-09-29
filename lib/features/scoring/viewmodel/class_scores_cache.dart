import 'package:flutter/foundation.dart';

import '../model/scoring_models.dart';
import '../repository/i_scoring_repository.dart';

/// Holds the scores of a whole class, loaded with a single leaderboard request.
///
/// Member lists show a score badge per member; without this each badge would load
/// its own score, which means hundreds of requests for a large class.
class ClassScoresCache extends ChangeNotifier {
  ClassScoresCache(this._scoringRepository);

  final IScoringRepository _scoringRepository;

  /// classId -> (userId -> entry)
  final Map<String, Map<String, LeaderboardEntryModel>> _byClass = {};
  final Map<String, Future<void>> _inFlight = {};
  final Set<String> _loadFailed = {};

  bool isLoaded(String classId) => _byClass.containsKey(classId);
  bool hasFailed(String classId) => _loadFailed.contains(classId);

  LeaderboardEntryModel? entryFor(String classId, String userId) =>
      _byClass[classId]?[userId];

  /// Loads the class scores once. Concurrent callers share the same request.
  Future<void> ensureLoaded(String classId) {
    if (classId.isEmpty || _byClass.containsKey(classId)) {
      return Future.value();
    }
    return _inFlight.putIfAbsent(classId, () async {
      final result = await _scoringRepository.getLeaderboard(
        classId,
        limit: 500,
      );
      result.fold(
        (error) {
          _loadFailed.add(classId);
          if (kDebugMode) {
            print('⚠️ [ClassScoresCache] Could not load scores for $classId: $error');
          }
        },
        (entries) {
          _loadFailed.remove(classId);
          _byClass[classId] = {
            for (final entry in entries) entry.userId: entry,
          };
        },
      );
      _inFlight.remove(classId);
      notifyListeners();
    });
  }

  /// Drops cached scores so the next badge build reloads them.
  void invalidate([String? classId]) {
    if (classId == null) {
      _byClass.clear();
      _loadFailed.clear();
    } else {
      _byClass.remove(classId);
      _loadFailed.remove(classId);
    }
    notifyListeners();
  }
}
