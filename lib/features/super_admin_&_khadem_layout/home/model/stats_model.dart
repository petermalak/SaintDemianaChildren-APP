class StatsModel {
  final num totalUsers;
  final num attendanceRate;
  final num eftekadCompletionRate;
  final num totalClasses;

  StatsModel({
    required this.totalUsers,
    required this.attendanceRate,
    required this.eftekadCompletionRate,
    required this.totalClasses,
  });

  factory StatsModel.fromJson(Map<String, dynamic> json) {
    return StatsModel(
      totalUsers: json['totalUsers'] ?? 0,
      attendanceRate: json['attendanceRate'] ?? 0,
      eftekadCompletionRate: json['eftekadCompletionRate'] ?? 0,
      totalClasses: json['totalClasses'] ?? 0,
    );
  }
}
