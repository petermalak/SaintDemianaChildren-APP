import 'package:dio/dio.dart';
import 'network_utils_stub.dart' if (dart.library.io) 'network_utils_io.dart'
    as network_utils;
import 'package:flutter/foundation.dart';
import 'package:saint_demiana_children/core/constants/api_endpoints.dart';
import 'package:saint_demiana_children/core/services/interface/i_api_service.dart';
import 'package:saint_demiana_children/core/services/interface/i_storage_service.dart';
import 'package:saint_demiana_children/features/profile/repository/i_profile_repository.dart';
import '../di/service_locator.dart';
import 'logging_service.dart';
import 'sync_queue_service.dart';

class ApiService implements IApiService {
  late Dio _dio;
  static ApiService? _instance;

  ApiService._() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
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

  /// The configured client (auth, logging, offline cache), used to replay queued writes.
  Dio get dio => _dio;

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

          final queue = SyncQueueService.instance;
          if (queue.isQueueable(options)) {
            queue.tagRequest(options);
            // Earlier operations are still waiting: queue behind them to keep order.
            if (queue.hasPendingForCurrentUser()) {
              await queue.enqueue(options);
              return handler.resolve(queue.queuedResponse(options));
            }
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
          final status = response.statusCode ?? 0;
          final fromCache = response.extra['fromCache'] == true;
          final queued = response.isQueued;
          if (fromCache) {
            SyncQueueService.instance.noteOffline(usingCache: true);
          } else if (!queued && status < 400) {
            SyncQueueService.instance.noteOnline();
            if (response.requestOptions.method == 'GET' &&
                !_isBulkPayload(response.data) &&
                (response.data is Map || response.data is List)) {
              sl<IStorageService>().cacheResponse(
                  _cacheKey(response.requestOptions), response.data);
            }
          }
          // Log the response
          _logger.logResponse(
            response.requestOptions.method,
            '${response.requestOptions.baseUrl}${response.requestOptions.path}',
            response.statusCode ?? 0,
            body: _responseSummary(response.data),
          );

          handler.next(response);
        },
        onError: (error, handler) async {
          // Log the error
          _logger.error(
            'API Error: ${error.message}',
            tag: 'API',
            error: error,
            stackTrace: error.stackTrace,
          );

          // Token expired or invalid: clear session so user must login again
          if (error.response?.statusCode == 401) {
            sl<IProfileRepository>().user = null;
            if (kDebugMode) {
              print('🔐 [API] 401 Unauthorized - session cleared');
            }
          }

          // Offline: serve the last successful response for this GET, if any
          if (error.requestOptions.method == 'GET' && _isOfflineError(error)) {
            SyncQueueService.instance.noteOffline();
            final cacheKey = _cacheKey(error.requestOptions);
            final cached = sl<IStorageService>().getCachedResponse(cacheKey);
            if (cached != null) {
              if (kDebugMode) {
                print('📴 [API] Offline - serving cached ${error.requestOptions.path}');
              }
              return handler.resolve(Response(
                requestOptions: error.requestOptions,
                data: cached,
                statusCode: 200,
                extra: {'fromCache': true},
              ));
            }
          }

          // Offline write: keep it on the device and send it when the connection is back
          final queue = SyncQueueService.instance;
          if (_isOfflineError(error)) queue.noteOffline();
          if (_isOfflineError(error) && queue.isQueueable(error.requestOptions)) {
            await queue.enqueue(error.requestOptions);
            return handler.resolve(queue.queuedResponse(error.requestOptions));
          }

          handler.next(error);
        },
      ),
    );
  }

  bool _isBulkPayload(dynamic data) {
    if (data is List) return data.length > 40;
    if (data is Map) {
      for (final key in const [
        'data',
        'makhdoum',
        'khadem',
        'attendanceRecords',
        'people',
        'marks',
      ]) {
        final value = data[key];
        if (value is List && value.length > 40) return true;
      }
    }
    return false;
  }

  String _responseSummary(dynamic data) {
    if (data is List) return 'list of ${data.length}';
    if (data is Map) return 'map keys: ${data.keys.take(8).join(', ')}';
    return data.runtimeType.toString();
  }

  String _cacheKey(RequestOptions options) {
    final userId = sl<IProfileRepository>().user?.id ?? '';
    return '$userId|${options.uri}';
  }

  bool _isOfflineError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return true;
      case DioExceptionType.unknown:
        return error.response == null;
      default:
        return false;
    }
  }

  @override
  Future<Response> get({
    required String path,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get(path, queryParameters: queryParameters);
    return response;
  }

  @override
  Future<Response> patch(
      {required String path,
      Map<String, dynamic>? queryParameters,
      body}) async {
    final response =
        await _dio.patch(path, queryParameters: queryParameters, data: body);
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
    return response;
  }

  @override
  Future<Response> postMultipart({
    required String path,
    String? filePath,
    List<int>? fileBytes,
    String fieldName = 'image',
    String fileName = 'image.jpg',
    String? contentType,
  }) async {
    assert(filePath != null || (fileBytes != null && fileBytes.isNotEmpty));
    final MultipartFile multipartFile;
    // On web, dart:io and MultipartFile.fromFile are not available; always use bytes.
    if (!kIsWeb && filePath != null && filePath.isNotEmpty) {
      multipartFile =
          await MultipartFile.fromFile(filePath, filename: fileName);
    } else {
      multipartFile = MultipartFile.fromBytes(
        fileBytes!,
        filename: fileName,
      );
    }
    final formData = FormData.fromMap({fieldName: multipartFile});
    final response = await _dio.post(path, data: formData);
    return response;
  }

  @override
  Future<bool> hasInternet() async {
    return network_utils.checkNetworkConnectivity();
  }

  @override
  String handleError(DioException error) {
    if (kDebugMode) {
      print('🔐 [API] Error ${error.response?.statusCode} ${error.requestOptions.path}');
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'انتهت مهلة الاتصال. تحقق من الإنترنت ثم أعد المحاولة.';
      case DioExceptionType.badResponse:
        final int? statusCode = error.response?.statusCode;
        final rawMessage = error.response?.data;
        final String message = rawMessage is Map && rawMessage['message'] != null
            ? rawMessage['message'].toString()
            : 'حدث خطأ';

        switch (statusCode) {
          case 400:
            return message;
          case 401:
            return 'انتهت الجلسة. سجّل الدخول مرة أخرى.';
          case 403:
            return 'ليس لديك صلاحية لهذا الإجراء.';
          case 404:
            return 'البيانات غير موجودة.';
          case 500:
            return 'خطأ في الخادم. حاول مرة أخرى.';
          default:
            return message;
        }
      case DioExceptionType.cancel:
        return 'تم إلغاء الطلب.';
      case DioExceptionType.connectionError:
        return 'لا يوجد اتصال بالإنترنت.';
      default:
        return 'حدث خطأ غير متوقع. حاول مرة أخرى.';
    }
  }
}
