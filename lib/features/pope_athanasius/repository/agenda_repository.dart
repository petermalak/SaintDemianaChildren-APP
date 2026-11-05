import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/services/interface/i_api_service.dart';
import '../model/agenda_model.dart';
import 'i_agenda_repository.dart';

class AgendaRepository implements IAgendaRepository {
  final IApiService _apiService;

  AgendaRepository(this._apiService);

  @override
  Future<Either<String, PhaseAgenda>> getMyAgenda() {
    return _load(ApiEndpoints.popeAgendaMine);
  }

  @override
  Future<Either<String, PhaseAgenda>> getAgendaForPhase(int phase) {
    return _load(ApiEndpoints.popeAgenda, queryParameters: {'phase': phase});
  }

  Future<Either<String, PhaseAgenda>> _load(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _apiService.get(
        path: path,
        queryParameters: queryParameters,
      );
      final body = response.data;
      if (body is Map && body['success'] == true) {
        final data = body['data'];
        if (data is Map && data['phases'] is List && (data['phases'] as List).isNotEmpty) {
          return right(PhaseAgenda.fromJson(Map<String, dynamic>.from(data['phases'][0] as Map)));
        }
        if (data is Map) {
          return right(PhaseAgenda.fromJson(Map<String, dynamic>.from(data)));
        }
      }
      return left('تعذر تحميل المنهج');
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left(e.toString());
    }
  }
}
