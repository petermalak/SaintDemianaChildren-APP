import 'package:dartz/dartz.dart';

import '../model/stats_model.dart';

abstract class IHomeRepository {
  Future<Either<String, StatsModel>> fetchStats({String? classId});
}
