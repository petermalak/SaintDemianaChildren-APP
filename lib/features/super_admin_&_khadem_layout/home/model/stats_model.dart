class StatsModel {
  final num totalUsers;
  final num attendanceRate;
  final num eftekadCompletionRate;
  final num totalClasses;

  final String? lastFridayDate;
  final num lastFridayAttendedCount;
  final num lastFridayTotalMembers;
  final num lastFridayEftekadCompleted;
  final num lastFridayEftekadTotal;

  final num totalAttendances;
  final num recentAttendances;
  final Map<String, num> attendanceByType;

  final num totalEftekads;
  final num recentEftekads;
  final Map<String, num> eftekadByStatus;
  final Map<String, num> eftekadByType;

  StatsModel({
    required this.totalUsers,
    required this.attendanceRate,
    required this.eftekadCompletionRate,
    required this.totalClasses,
    this.lastFridayDate,
    this.lastFridayAttendedCount = 0,
    this.lastFridayTotalMembers = 0,
    this.lastFridayEftekadCompleted = 0,
    this.lastFridayEftekadTotal = 0,
    this.totalAttendances = 0,
    this.recentAttendances = 0,
    this.attendanceByType = const {},
    this.totalEftekads = 0,
    this.recentEftekads = 0,
    this.eftekadByStatus = const {},
    this.eftekadByType = const {},
  });

  factory StatsModel.fromJson(Map<String, dynamic> json) {
    final overview = json['overview'] is Map
        ? Map<String, dynamic>.from(json['overview'] as Map)
        : json;
    final attendance = json['attendance'] is Map
        ? Map<String, dynamic>.from(json['attendance'] as Map)
        : const <String, dynamic>{};
    final eftekad = json['eftekad'] is Map
        ? Map<String, dynamic>.from(json['eftekad'] as Map)
        : const <String, dynamic>{};

    final totalUsers = _num(overview['totalUsers']);
    final totalAttendances = _num(
      overview['totalAttendances'] ?? attendance['total'],
    );

    return StatsModel(
      totalUsers: totalUsers,
      attendanceRate: totalUsers > 0
          ? ((totalAttendances / totalUsers) * 100).round()
          : 0,
      eftekadCompletionRate: _num(eftekad['completionRate']),
      totalClasses: _num(overview['totalClasses']),
      lastFridayDate: overview['lastFridayDate']?.toString(),
      lastFridayAttendedCount: _num(overview['lastFridayAttendedCount']),
      lastFridayTotalMembers: _num(overview['lastFridayTotalMembers']),
      lastFridayEftekadCompleted: _num(overview['lastFridayEftekadCompleted']),
      lastFridayEftekadTotal: _num(overview['lastFridayEftekadTotal']),
      totalAttendances: totalAttendances,
      recentAttendances: _num(attendance['recentCount']),
      attendanceByType: _counts(attendance['byType'], 'type'),
      totalEftekads: _num(overview['totalEftekads'] ?? eftekad['total']),
      recentEftekads: _num(eftekad['recentCount']),
      eftekadByStatus: _counts(eftekad['byStatus'], 'status'),
      eftekadByType: _counts(eftekad['byType'], 'type'),
    );
  }

  static num _num(dynamic value) {
    if (value is num) return value;
    return num.tryParse('${value ?? ''}') ?? 0;
  }

  static Map<String, num> _counts(dynamic raw, String keyName) {
    if (raw is! List) return const {};
    final map = <String, num>{};
    for (final item in raw) {
      if (item is! Map) continue;
      final key = item[keyName]?.toString();
      if (key == null || key.isEmpty) continue;
      map[key] = _num(item['count']);
    }
    return map;
  }
}
