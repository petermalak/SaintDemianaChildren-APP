import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:saint_demiana_children/core/constants/api_endpoints.dart';
import 'package:saint_demiana_children/core/services/interface/i_api_service.dart';
import 'package:saint_demiana_children/features/profile/repository/i_profile_repository.dart';
import '../di/service_locator.dart';
import 'logging_service.dart';

class ApiService implements IApiService {
  late Dio _dio;
  static ApiService? _instance;

  ApiService._() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 45),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _setupInterceptors();
  }

  LoggingService get _logger => LoggingService.instance;

  static ApiService get instance {
    _instance ??= ApiService._();
    return _instance!;
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = sl<IProfileRepository>().user?.token;

          // Debug logging
          if (kDebugMode) {
            print('🔐 [API] Making request to: ${options.path}');
            print('🔐 [API] Token exists: ${token != null}');
            if (token != null) {
              print('🔐 [API] Token preview: ${token.substring(0, 20)}...');
            }
          }

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Log the request
          _logger.logRequest(
            options.method,
            '${options.baseUrl}${options.path}',
            headers: options.headers,
            body: options.data,
          );

          handler.next(options);
        },
        onResponse: (response, handler) {
          print(response.data);
          // Log the response
          _logger.logResponse(
            response.requestOptions.method,
            '${response.requestOptions.baseUrl}${response.requestOptions.path}',
            response.statusCode ?? 0,
            body: response.data,
          );

          handler.next(response);
        },
        onError: (error, handler) {
          // Log the error
          _logger.error(
            'API Error: ${error.message}',
            tag: 'API',
            error: error,
            stackTrace: error.stackTrace,
          );

          // Handle common errors
          if (error.response?.statusCode == 401) {}

          handler.next(error);
        },
      ),
    );
  }

  @override
  Future<Response> get({
    required String path,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get(path, queryParameters: queryParameters);
    if (kDebugMode) {
      print(response.data);
    }
    return response;
  }

  @override
  Future<Response> patch(
      {required String path,
      Map<String, dynamic>? queryParameters,
      body}) async {
    final response = await _dio.patch(path, queryParameters: queryParameters);
    if (kDebugMode) {
      print(response.data);
    }
    return response;
  }

  @override
  Future<Response> put({
    required String path,
    Map<String, dynamic>? queryParameters,
    dynamic body,
  }) async {
    final response = await _dio.put(
      path,
      queryParameters: queryParameters,
      data: body,
    );
    if (kDebugMode) {
      print(response.data);
    }
    return response;
  }

  @override
  Future<Response> delete({
    required String path,
    Map<String, dynamic>? queryParameters,
    dynamic body,
  }) async {
    final response = await _dio.delete(
      path,
      queryParameters: queryParameters,
      data: body,
    );
    if (kDebugMode) {
      print(response.data);
    }
    return response;
  }

  @override
  Future<Response> post({
    required String path,
    Map<String, dynamic>? queryParameters,
    dynamic body,
  }) async {
    final response = await _dio.post(
      path,
      queryParameters: queryParameters,
      data: body,
    );
    if (kDebugMode) {
      print(response.data);
    }
    return response;
  }

  @override
  Future<bool> hasInternet() async {
    if (kIsWeb) {
      try {
        final response = await Dio().get('https://www.google.com',
            options: Options(
              receiveTimeout: const Duration(seconds: 10),
              sendTimeout: const Duration(seconds: 10),
            ));
        return response.statusCode == 200;
      } catch (_) {
        return false;
      }
    } else {
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 15));
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException {
        return false;
      }
    }
  }

  @override
  String handleError(DioException error) {
    print(error.response?.data);
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        final int? statusCode = error.response?.statusCode;
        final String message =
            error.response?.data?['message'] ?? 'An error occurred';

        switch (statusCode) {
          case 400:
            return 'Bad request: $message';
          case 401:
            return 'Unauthorized. Please login again.';
          case 403:
            return 'Access denied. You don\'t have permission to perform this action.';
          case 404:
            return 'Resource not found.';
          case 500:
            return 'Server error. Please try again later.';
          default:
            return 'Error $statusCode: $message';
        }
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
