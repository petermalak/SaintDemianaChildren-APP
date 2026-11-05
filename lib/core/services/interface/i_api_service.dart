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

  /// Upload a file as multipart. Provide either [filePath] (mobile) or [fileBytes] (web).
  /// [contentType] e.g. 'image/jpeg' – required for [fileBytes] on web so server accepts the file.
  Future<Response> postMultipart({
    required String path,
    String? filePath,
    List<int>? fileBytes,
    String fieldName = 'image',
    String fileName = 'image.jpg',
    String? contentType,
  });

  String handleError(DioException error);
}
