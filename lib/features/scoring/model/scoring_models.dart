import 'package:equatable/equatable.dart';

/// Scoring System Configuration Model
class ScoringConfigModel extends Equatable {
  final String id;
  final String? classId;
  final String systemName;
  final bool isEnabled;
  final int massPoints;
  final int generalMeetingPoints;
  final int specialMeetingPoints;
  final int praisePoints;
  final List<ScoringTierModel>? tiers;
  final ClassInfo? classInfo;

  const ScoringConfigModel({
    required this.id,
    this.classId,
    required this.systemName,
    required this.isEnabled,
    required this.massPoints,
    required this.generalMeetingPoints,
    required this.specialMeetingPoints,
    required this.praisePoints,
    this.tiers,
    this.classInfo,
  });

  factory ScoringConfigModel.fromJson(Map<String, dynamic> json) {
    return ScoringConfigModel(
      id: json['id'] ?? '',
      classId: json['classId'],
      systemName: json['systemName'] ?? 'Taio',
      isEnabled: json['isEnabled'] ?? true,
      massPoints: json['massPoints'] ?? 50,
      generalMeetingPoints: json['generalMeetingPoints'] ?? 20,
      specialMeetingPoints: json['specialMeetingPoints'] ?? 20,
      praisePoints: json['praisePoints'] ?? 10,
      tiers: json['tiers'] != null
          ? (json['tiers'] as List)
              .map((tier) => ScoringTierModel.fromJson(tier))
              .toList()
          : null,
      classInfo:
          json['class'] != null ? ClassInfo.fromJson(json['class']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classId': classId,
      'systemName': systemName,
      'isEnabled': isEnabled,
      'massPoints': massPoints,
      'generalMeetingPoints': generalMeetingPoints,
      'specialMeetingPoints': specialMeetingPoints,
      'praisePoints': praisePoints,
    };
  }

  ScoringConfigModel copyWith({
    String? id,
    String? classId,
    String? systemName,
    bool? isEnabled,
    int? massPoints,
    int? generalMeetingPoints,
    int? specialMeetingPoints,
    int? praisePoints,
    List<ScoringTierModel>? tiers,
    ClassInfo? classInfo,
  }) {
    return ScoringConfigModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      systemName: systemName ?? this.systemName,
      isEnabled: isEnabled ?? this.isEnabled,
      massPoints: massPoints ?? this.massPoints,
      generalMeetingPoints: generalMeetingPoints ?? this.generalMeetingPoints,
      specialMeetingPoints: specialMeetingPoints ?? this.specialMeetingPoints,
      praisePoints: praisePoints ?? this.praisePoints,
      tiers: tiers ?? this.tiers,
      classInfo: classInfo ?? this.classInfo,
    );
  }

  @override
  List<Object?> get props => [
        id,
        classId,
        systemName,
        isEnabled,
        massPoints,
        generalMeetingPoints,
        specialMeetingPoints,
        praisePoints,
        tiers,
        classInfo,
      ];
}

/// Scoring Tier Model
class ScoringTierModel extends Equatable {
  final String id;
  final String configId;
  final String name;
  final int minPoints;
  final int? maxPoints;
  final String? color;
  final String? icon;
  final int order;

  const ScoringTierModel({
    required this.id,
    required this.configId,
    required this.name,
    required this.minPoints,
    this.maxPoints,
    this.color,
    this.icon,
    required this.order,
  });

  factory ScoringTierModel.fromJson(Map<String, dynamic> json) {
    return ScoringTierModel(
      id: json['id'] ?? '',
      configId: json['configId'] ?? '',
      name: json['name'] ?? '',
      minPoints: json['minPoints'] ?? 0,
      maxPoints: json['maxPoints'],
      color: json['color'],
      icon: json['icon'],
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'configId': configId,
      'name': name,
      'minPoints': minPoints,
      'maxPoints': maxPoints,
      'color': color,
      'icon': icon,
      'order': order,
    };
  }

  bool isInRange(int points) {
    if (points < minPoints) return false;
    if (maxPoints == null) return true;
    return points <= maxPoints!;
  }

  double calculateProgress(int currentPoints) {
    if (maxPoints == null) return 100.0;
    final range = maxPoints! - minPoints;
    final progress = currentPoints - minPoints;
    return ((progress / range) * 100).clamp(0.0, 100.0);
  }

  int pointsToNextTier(int currentPoints) {
    if (maxPoints == null) return 0;
    return (maxPoints! + 1 - currentPoints).clamp(0, double.maxFinite.toInt());
  }

  @override
  List<Object?> get props =>
      [id, configId, name, minPoints, maxPoints, color, icon, order];
}

/// User Score Model
class UserScoreModel extends Equatable {
  final String id;
  final String userId;
  final String classId;
  final int totalPoints;
  final DateTime lastUpdated;
  final UserInfo? user;
  final ScoringTierModel? currentTier;
  final ClassInfo? classInfo;
  final int? rank;
  final TierProgress? tierProgress;
  final ScoreStats? stats;

  const UserScoreModel({
    required this.id,
    required this.userId,
    required this.classId,
    required this.totalPoints,
    required this.lastUpdated,
    this.user,
    this.currentTier,
    this.classInfo,
    this.rank,
    this.tierProgress,
    this.stats,
  });

  factory UserScoreModel.fromJson(Map<String, dynamic> json) {
    return UserScoreModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      classId: json['classId'] ?? '',
      totalPoints: json['totalPoints'] ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
      user: json['user'] != null ? UserInfo.fromJson(json['user']) : null,
      currentTier: json['currentTier'] != null
          ? ScoringTierModel.fromJson(json['currentTier'])
          : null,
      classInfo:
          json['class'] != null ? ClassInfo.fromJson(json['class']) : null,
      rank: json['rank'],
      tierProgress: json['tierProgress'] != null
          ? TierProgress.fromJson(json['tierProgress'])
          : null,
      stats: json['stats'] != null ? ScoreStats.fromJson(json['stats']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'classId': classId,
      'totalPoints': totalPoints,
      'lastUpdated': lastUpdated.toIso8601String(),
      'rank': rank,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        classId,
        totalPoints,
        lastUpdated,
        user,
        currentTier,
        classInfo,
        rank,
        tierProgress,
        stats,
      ];
}

/// Score Transaction Model
class ScoreTransactionModel extends Equatable {
  final String id;
  final String userId;
  final int points;
  final String transactionType;
  final String? reason;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final AwardedBy? awardedBy;
  final UserScoreInfo? userScore;
  final ClassInfo? classInfo;
  final String? attendanceId;

  const ScoreTransactionModel({
    required this.id,
    required this.userId,
    required this.points,
    required this.transactionType,
    this.reason,
    this.metadata,
    required this.createdAt,
    this.awardedBy,
    this.userScore,
    this.classInfo,
    this.attendanceId,
  });

  factory ScoreTransactionModel.fromJson(Map<String, dynamic> json) {
    return ScoreTransactionModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      points: json['points'] ?? 0,
      transactionType: json['transactionType'] ?? '',
      reason: json['reason'],
      metadata: json['metadata'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      awardedBy: json['awardedBy'] != null
          ? AwardedBy.fromJson(json['awardedBy'])
          : null,
      userScore: json['userScore'] != null
          ? UserScoreInfo.fromJson(json['userScore'])
          : null,
      classInfo:
          json['class'] != null ? ClassInfo.fromJson(json['class']) : null,
      attendanceId: json['attendanceId'],
    );
  }

  bool get isPositive => points > 0;
  bool get isNegative => points < 0;
  bool get isAttendanceBased => transactionType == 'attendance';

  String getTransactionTypeLabel() {
    switch (transactionType) {
      case 'attendance':
        return 'حضور';
      case 'manual_add':
        return 'إضافة يدوية';
      case 'manual_remove':
        return 'خصم يدوي';
      case 'bonus':
        return 'مكافأة';
      case 'penalty':
        return 'عقوبة';
      case 'adjustment':
        return 'تعديل';
      default:
        return 'معاملة';
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        points,
        transactionType,
        reason,
        metadata,
        createdAt,
        awardedBy,
        userScore,
        classInfo,
        attendanceId,
      ];
}

/// Leaderboard Entry Model
class LeaderboardEntryModel extends Equatable {
  final int rank;
  final String userId;
  final int totalPoints;
  final DateTime lastUpdated;
  final UserInfo? user;
  final ScoringTierModel? tier;

  const LeaderboardEntryModel({
    required this.rank,
    required this.userId,
    required this.totalPoints,
    required this.lastUpdated,
    this.user,
    this.tier,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      rank: json['rank'] ?? 0,
      userId: json['userId'] ?? '',
      totalPoints: json['totalPoints'] ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
      user: json['user'] != null ? UserInfo.fromJson(json['user']) : null,
      tier:
          json['tier'] != null ? ScoringTierModel.fromJson(json['tier']) : null,
    );
  }

  @override
  List<Object?> get props =>
      [rank, userId, totalPoints, lastUpdated, user, tier];
}

/// Helper Models

class UserInfo extends Equatable {
  final String id;
  final String name;
  final String? profileImage;
  final String? role;

  const UserInfo({
    required this.id,
    required this.name,
    this.profileImage,
    this.role,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      profileImage: json['profileImage'],
      role: json['role'],
    );
  }

  @override
  List<Object?> get props => [id, name, profileImage, role];
}

class ClassInfo extends Equatable {
  final String id;
  final String name;

  const ClassInfo({
    required this.id,
    required this.name,
  });

  factory ClassInfo.fromJson(Map<String, dynamic> json) {
    return ClassInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name];
}

class AwardedBy extends Equatable {
  final String id;
  final String name;
  final String role;

  const AwardedBy({
    required this.id,
    required this.name,
    required this.role,
  });

  factory AwardedBy.fromJson(Map<String, dynamic> json) {
    return AwardedBy(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, role];
}

class UserScoreInfo extends Equatable {
  final String id;
  final String classId;

  const UserScoreInfo({
    required this.id,
    required this.classId,
  });

  factory UserScoreInfo.fromJson(Map<String, dynamic> json) {
    return UserScoreInfo(
      id: json['id'] ?? '',
      classId: json['classId'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, classId];
}

class TierProgress extends Equatable {
  final int current;
  final int min;
  final int? max;
  final double percentage;
  final int pointsToNext;

  const TierProgress({
    required this.current,
    required this.min,
    this.max,
    required this.percentage,
    required this.pointsToNext,
  });

  factory TierProgress.fromJson(Map<String, dynamic> json) {
    return TierProgress(
      current: json['current'] ?? 0,
      min: json['min'] ?? 0,
      max: json['max'],
      percentage: (json['percentage'] ?? 0).toDouble(),
      pointsToNext: json['pointsToNext'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [current, min, max, percentage, pointsToNext];
}

class ScoreStats extends Equatable {
  final int totalGained;
  final int totalLost;
  final int netPoints;
  final int transactionCount;
  final int attendancePoints;
  final int manualPoints;
  final int? averagePoints;

  const ScoreStats({
    required this.totalGained,
    required this.totalLost,
    required this.netPoints,
    required this.transactionCount,
    required this.attendancePoints,
    required this.manualPoints,
    this.averagePoints,
  });

  factory ScoreStats.fromJson(Map<String, dynamic> json) {
    return ScoreStats(
      totalGained: json['totalGained'] ?? 0,
      totalLost: json['totalLost'] ?? 0,
      netPoints: json['netPoints'] ?? 0,
      transactionCount: json['transactionCount'] ?? 0,
      attendancePoints: json['attendancePoints'] ?? 0,
      manualPoints: json['manualPoints'] ?? 0,
      averagePoints: json['averagePoints'],
    );
  }

  @override
  List<Object?> get props => [
        totalGained,
        totalLost,
        netPoints,
        transactionCount,
        attendancePoints,
        manualPoints,
        averagePoints,
      ];
}
