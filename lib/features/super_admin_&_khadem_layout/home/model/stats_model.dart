class StatsModel {
  final num totalUsers;
  final num attendanceRate;
  final num eftekadCompletionRate;
  final num totalClasses;

  // Last Friday stats
  final String? lastFridayDate;
  final num lastFridayAttendedCount;
  final num lastFridayTotalMembers;
  final num lastFridayEftekadCompleted;
  final num lastFridayEftekadTotal;

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
  });

  factory StatsModel.fromJson(Map<String, dynamic> json) {
    print('📊 Parsing stats from JSON: $json'); // Debug

    // Handle nested structure: data.overview contains the stats
    final overview = json['overview'] ?? json;

    final totalUsers = overview['totalUsers'] ?? 0;
    final totalAttendances = overview['totalAttendances'] ?? 0;
    final totalClasses = overview['totalClasses'] ?? 0;

    // Calculate attendance rate (if we have attendance data)
    final attendanceRate =
        totalUsers > 0 ? ((totalAttendances / totalUsers) * 100).round() : 0;

    // Get eftekad completion rate from json
    final eftekad = json['eftekad'] ?? {};
    final eftekadCompletionRate = eftekad['completionRate'] ?? 0;

    // Get last Friday stats
    final lastFridayDate = overview['lastFridayDate'];
    final lastFridayAttendedCount = overview['lastFridayAttendedCount'] ?? 0;
    final lastFridayTotalMembers = overview['lastFridayTotalMembers'] ?? 0;
    final lastFridayEftekadCompleted =
        overview['lastFridayEftekadCompleted'] ?? 0;
    final lastFridayEftekadTotal = overview['lastFridayEftekadTotal'] ?? 0;

    print(
        '📊 Parsed - Users: $totalUsers, Attendance Rate: $attendanceRate, Classes: $totalClasses');
    print(
        '📊 Last Friday - Attendance: $lastFridayAttendedCount/$lastFridayTotalMembers, Eftekad: $lastFridayEftekadCompleted/$lastFridayEftekadTotal');

    return StatsModel(
      totalUsers: totalUsers,
      attendanceRate: attendanceRate,
      eftekadCompletionRate: eftekadCompletionRate,
      totalClasses: totalClasses,
      lastFridayDate: lastFridayDate,
      lastFridayAttendedCount: lastFridayAttendedCount,
      lastFridayTotalMembers: lastFridayTotalMembers,
      lastFridayEftekadCompleted: lastFridayEftekadCompleted,
      lastFridayEftekadTotal: lastFridayEftekadTotal,
    );
  }
}
