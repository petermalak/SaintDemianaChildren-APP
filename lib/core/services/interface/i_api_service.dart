import 'package:dio/dio.dart';

abstract class IApiService {
  Future<bool> hasInternet();

  Future<Response> get({
    required String path,
    Map<String, dynamic>? queryParameters,
  });

  Future<Response> post({
    required String path,
    Map<String, dynamic>? queryParameters,
    dynamic body,
  });

  Future<Response> put({
    required String path,
    Map<String, dynamic>? queryParameters,
    dynamic body,
  });

  Future<Response> delete({
    required String path,
    Map<String, dynamic>? queryParameters,
    dynamic body,
  });

  Future<Response> patch({
    required String path,
    Map<String, dynamic>? queryParameters,
    dynamic body,
  });

  String handleError(DioException error);
}
