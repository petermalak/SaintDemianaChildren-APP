import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:saint_demiana_children/core/services/interface/i_api_service.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/home/model/stats_model.dart';

import '../../../../core/constants/api_endpoints.dart';
import 'i_home_repository.dart';

class HomeRepository implements IHomeRepository {
  final IApiService _apiService;

  HomeRepository(this._apiService);

  @override
  Future<Either<String, StatsModel>> fetchStats() async {
    try {
      final response = await _apiService.get(path: ApiEndpoints.stats);

      return right(StatsModel.fromJson(response.data['data']));
      // return right(StatsModel(
      //   totalUsers: 20,
      //   attendanceRate: 5,
      //   eftekadCompletionRate: 3,
      //   totalClasses: 4,
      // ));
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left("An unexpected error occurred");
    }
  }
}
