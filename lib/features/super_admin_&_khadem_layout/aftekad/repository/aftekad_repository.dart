import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/model/aftekad_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/repository/i_aftekad_repository.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/interface/i_api_service.dart';

class AftekadRepository implements IAftekadRepository {
  final IApiService _apiService;
  Map<String, int>? _lastMakhdoumsMissedFridays;

  AftekadRepository(this._apiService);

  Map<String, int>? get lastMakhdoumsMissedFridays =>
      _lastMakhdoumsMissedFridays;

  @override
  Future<Either<String, List<AftekadModel>>> getAftekadByWeek(
      String fridayDate, String khademId,
      {String? classId}) async {
    try {
      final queryParameters = {
        "status": "completed",
        "khademId": khademId,
      };

      if (classId != null && classId.isNotEmpty) {
        queryParameters["classId"] = classId;
      }

      final response = await _apiService.get(
          path: ApiEndpoints.aftekadByWeek(fridayDate),
          queryParameters: queryParameters);

      // Parse makhdoumsMissedFridays map from response if available
      final makhdoumsMissedFridaysData =
          response.data['makhdoumsMissedFridays'];
      if (makhdoumsMissedFridaysData != null &&
          makhdoumsMissedFridaysData is Map) {
        _lastMakhdoumsMissedFridays = Map<String, int>.from(
            makhdoumsMissedFridaysData.map((key, value) =>
                MapEntry(key.toString(), (value as num).toInt())));
      } else {
        _lastMakhdoumsMissedFridays = null;
      }

      final aftekads = (response.data['eftekads'] as List)
          .map((e) => AftekadModel.fromJson(e))
          .toList();

      return right(aftekads);
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
      await _apiService.post(path: ApiEndpoints.aftekad, body: {
        "type": type.name,
        "scheduledDate": date.toIso8601String(), // Required field
        "completedDate": date.toIso8601String(), // When it was completed
        "status": "completed", // Mark as completed
        "khademId": khademId,
        "makhdoumId": makhdoumId,
        "classId": classId,
        "notes": notes ?? ""
      });

      return right(unit);
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left("An unexpected error occurred");
    }
  }
}
