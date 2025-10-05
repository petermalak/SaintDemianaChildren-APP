class StatsModel {
  final num totalUsers;
  final num makhdoumCount;
  final num khademCount;

  StatsModel({
    required this.totalUsers,
    required this.makhdoumCount,
    required this.khademCount,
  });

  factory StatsModel.fromJson(Map<String, dynamic> json) {
    return StatsModel(
      totalUsers: json['total_users'] ?? 0,
      makhdoumCount: json['makhdoum_count'] ?? 0,
      khademCount: json['khadem_count'] ?? 0,
    );
  }
}
