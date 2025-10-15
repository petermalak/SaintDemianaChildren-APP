import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/model/aftekad_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/repository/i_aftekad_repository.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/interface/i_api_service.dart';

class AftekadRepository implements IAftekadRepository {
  final IApiService _apiService;

  AftekadRepository(this._apiService);

  @override
  Future<Either<String, List<AftekadModel>>> getAftekadByWeek(String fridayDate,String khademId) async {
    try {
      final response = await _apiService.get(path: ApiEndpoints.aftekadByWeek(fridayDate),queryParameters: {
        "status":"completed",
        "khademId":khademId
      });

      return right((response.data['eftekads'] as List)
          .map((e) => AftekadModel.fromJson(e))
          .toList());
      // return right([
      //   AftekadModel(
      //     id: "1",
      //     khademName: "John Doe",
      //     makhdoumId: "M001",
      //     makhdoumName: "Jane Smith",
      //     status: true,
      //     actualDate: DateTime.now().subtract(const Duration(days: 1)),
      //     type: AftekadType.phone_call,
      //   ),
      //   AftekadModel(
      //     id: "2",
      //     khademName: "Alice Johnson",
      //     makhdoumId: "M002",
      //     makhdoumName: "Bob Brown",
      //     status: false,
      //     actualDate: DateTime.now(),
      //     type: AftekadType.home_visit,
      //   ),
      //   AftekadModel(
      //     id: "3",
      //     khademName: "Charlie Davis",
      //     makhdoumId: "M003",
      //     makhdoumName: "Eve White",
      //     status: false,
      //     actualDate: null,
      //     type: AftekadType.whatsapp_message,
      //   ),
      // ]);
    } on DioException catch (e) {
      print(e.response?.data);
      return left(_apiService.handleError(e));
    } catch (e) {
      return left("An unexpected error occurred");
    }
  }

  @override
  Future<Either<String, Unit>> addAftekad(
      {required AftekadType type,
      required DateTime date,
      required String makhdoumId,
      required String khademId,
        required String classId,
      String? notes}) async {
    try {
      await _apiService.post(path: ApiEndpoints.aftekad,body: {
        "type": type.name,
        "completedDate": date.toIso8601String(),
        "khademId": khademId,
        "makhdoumId": makhdoumId,
        "classId":classId,
        "notes": notes
      });

      return right(unit);
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left("An unexpected error occurred");
    }
  }
}
