import 'package:equatable/equatable.dart';

class LevelProgress extends Equatable {
  final String levelId;
  final int stars;
  final bool completed;
  final double bestQuizScore;
  final int attempts;
  final int? bestTimeMs;

  const LevelProgress({
    required this.levelId,
    this.stars = 0,
    this.completed = false,
    this.bestQuizScore = 0,
    this.attempts = 0,
    this.bestTimeMs,
  });

  factory LevelProgress.fromJson(Map<String, dynamic> json) {
    return LevelProgress(
      levelId: json['levelId'] as String? ?? '',
      stars: json['stars'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
      bestQuizScore: (json['bestQuizScore'] as num?)?.toDouble() ?? 0,
      attempts: json['attempts'] as int? ?? 0,
      bestTimeMs: json['bestTimeMs'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'levelId': levelId,
        'stars': stars,
        'completed': completed,
        'bestQuizScore': bestQuizScore,
        'attempts': attempts,
        if (bestTimeMs != null) 'bestTimeMs': bestTimeMs,
      };

  LevelProgress copyWith({
    int? stars,
    bool? completed,
    double? bestQuizScore,
    int? attempts,
    int? bestTimeMs,
  }) {
    return LevelProgress(
      levelId: levelId,
      stars: stars ?? this.stars,
      completed: completed ?? this.completed,
      bestQuizScore: bestQuizScore ?? this.bestQuizScore,
      attempts: attempts ?? this.attempts,
      bestTimeMs: bestTimeMs ?? this.bestTimeMs,
    );
  }

  @override
  List<Object?> get props =>
      [levelId, stars, completed, bestQuizScore, attempts, bestTimeMs];
}

class UserCopticQuestProgress extends Equatable {
  final String userId;
  final String tier;
  final String lessonLanguage;
  final Map<String, Map<String, LevelProgress>> paths;
  final DateTime? lastPlayedAt;
  final int totalXp;
  final int streakDays;
  final String? lastPlayDate;

  const UserCopticQuestProgress({
    required this.userId,
    this.tier = 'T1',
    this.lessonLanguage = 'ar',
    this.paths = const {},
    this.lastPlayedAt,
    this.totalXp = 0,
    this.streakDays = 0,
    this.lastPlayDate,
  });

  factory UserCopticQuestProgress.empty(String userId) {
    return UserCopticQuestProgress(userId: userId);
  }

  factory UserCopticQuestProgress.fromJson(Map<String, dynamic> json) {
    final pathsRaw = _mapFrom(json['paths']);
    final paths = <String, Map<String, LevelProgress>>{};
    pathsRaw.forEach((pathId, levelsRaw) {
      final levelsMap = <String, LevelProgress>{};
      if (levelsRaw is Map) {
        Map<String, dynamic>.from(levelsRaw).forEach((levelId, progressRaw) {
          if (progressRaw is Map) {
            levelsMap[levelId.toString()] = LevelProgress.fromJson(
              Map<String, dynamic>.from(progressRaw),
            );
          }
        });
      }
      paths[pathId] = levelsMap;
    });

    return UserCopticQuestProgress(
      userId: json['userId'] as String? ?? '',
      tier: json['tier'] as String? ?? 'T1',
      lessonLanguage: json['lessonLanguage'] as String? ?? 'ar',
      paths: paths,
      lastPlayedAt: json['lastPlayedAt'] != null
          ? DateTime.tryParse(json['lastPlayedAt'] as String)
          : null,
      totalXp: json['totalXp'] as int? ?? 0,
      streakDays: json['streakDays'] as int? ?? 0,
      lastPlayDate: json['lastPlayDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final pathsJson = <String, dynamic>{};
    paths.forEach((pathId, levels) {
      pathsJson[pathId] = {
        for (final entry in levels.entries) entry.key: entry.value.toJson(),
      };
    });
    return {
      'userId': userId,
      'tier': tier,
      'lessonLanguage': lessonLanguage,
      'paths': pathsJson,
      'totalXp': totalXp,
      'streakDays': streakDays,
      if (lastPlayDate != null) 'lastPlayDate': lastPlayDate,
      if (lastPlayedAt != null) 'lastPlayedAt': lastPlayedAt!.toIso8601String(),
    };
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  UserCopticQuestProgress withStreakUpdate(DateTime now) {
    final today = _dateKey(now);
    if (lastPlayDate == null) {
      return copyWith(streakDays: 1, lastPlayDate: today);
    }
    if (lastPlayDate == today) return this;

    final last = DateTime.tryParse('${lastPlayDate!}T12:00:00');
    if (last == null) return copyWith(streakDays: 1, lastPlayDate: today);

    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(last.year, last.month, last.day))
        .inDays;
    if (diff == 1) {
      return copyWith(streakDays: streakDays + 1, lastPlayDate: today);
    }
    return copyWith(streakDays: 1, lastPlayDate: today);
  }

  int totalStars() {
    var sum = 0;
    for (final path in paths.values) {
      for (final level in path.values) {
        sum += level.stars;
      }
    }
    return sum;
  }

  int completedLevelsCount() {
    var count = 0;
    for (final path in paths.values) {
      for (final level in path.values) {
        if (level.completed) count++;
      }
    }
    return count;
  }

  LevelProgress levelProgress(String pathId, String levelId) {
    return paths[pathId]?[levelId] ?? LevelProgress(levelId: levelId);
  }

  bool isLevelUnlocked(
    String pathId,
    String levelId,
    List<String> orderedLevelIds,
  ) {
    final index = orderedLevelIds.indexOf(levelId);
    if (index <= 0) return true;
    final previousId = orderedLevelIds[index - 1];
    return levelProgress(pathId, previousId).completed;
  }

  UserCopticQuestProgress copyWith({
    String? tier,
    String? lessonLanguage,
    Map<String, Map<String, LevelProgress>>? paths,
    DateTime? lastPlayedAt,
    int? totalXp,
    int? streakDays,
    String? lastPlayDate,
  }) {
    return UserCopticQuestProgress(
      userId: userId,
      tier: tier ?? this.tier,
      lessonLanguage: lessonLanguage ?? this.lessonLanguage,
      paths: paths ?? this.paths,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      totalXp: totalXp ?? this.totalXp,
      streakDays: streakDays ?? this.streakDays,
      lastPlayDate: lastPlayDate ?? this.lastPlayDate,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        tier,
        lessonLanguage,
        paths,
        lastPlayedAt,
        totalXp,
        streakDays,
        lastPlayDate,
      ];
}

Map<String, dynamic> _mapFrom(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}
