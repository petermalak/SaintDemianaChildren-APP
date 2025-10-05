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

  // Get the logging service instance
  LoggingService get _logger => LoggingService.instance;

  static ApiService get instance {
    _instance ??= ApiService._();
    return _instance!;
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token to requests
          final token = sl<IProfileRepository>().user?.token;
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
  }) async {
    final response = await _dio.delete(path, queryParameters: queryParameters);
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

  Future<Map<String, dynamic>> updateMyProfile(
      Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/users/me', data: data);
      return response.data;
    } on DioException catch (e) {
      throw handleError(e);
    }
  }

  Future<String> uploadProfileImage(String imagePath) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
      });

      final response = await _dio.post(
        '/users/me/profile-image',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return response.data['imageUrl'];
    } on DioException catch (e) {
      throw handleError(e);
    }
  }

  Future<Map<String, dynamic>> getUserById(String id) async {
    try {
      final response = await _dio.get('/users/$id');
      return response.data;
    } on DioException catch (e) {
      throw handleError(e);
    }
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

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    // Remove empty id field as it should be generated by the server
    final cleanUserData = Map<String, dynamic>.from(userData);
    cleanUserData.remove('id');

    // Remove null or empty profileImage to avoid validation issues
    if (cleanUserData['profileImage'] == null ||
        cleanUserData['profileImage'] == '') {
      cleanUserData.remove('profileImage');
    }

    try {
      // Log the exact data being sent
      _logger.logRequest(
        'POST',
        '${_dio.options.baseUrl}/users',
        headers: _dio.options.headers,
        body: cleanUserData,
      );

      final response = await _dio.post('/users', data: cleanUserData);

      _logger.logResponse(
        'POST',
        '${_dio.options.baseUrl}/users',
        response.statusCode ?? 0,
        body: response.data,
      );

      return response.data;
    } on DioException catch (e) {
      // Log more detailed error information
      _logger.error(
        'Create User Error: ${e.message}',
        tag: 'API',
        error: e,
        stackTrace: e.stackTrace,
      );

      if (e.response != null) {
        _logger.error(
          'Response data: ${e.response?.data}',
          tag: 'API',
        );
        _logger.error(
          'Response status: ${e.response?.statusCode}',
          tag: 'API',
        );
        _logger.error(
          'Response headers: ${e.response?.headers}',
          tag: 'API',
        );
      }

      // Also log the request that failed
      _logger.error(
        'Failed request data: $cleanUserData',
        tag: 'API',
      );

      throw handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateUser(
      String id, Map<String, dynamic> userData) async {
    try {
      // Check if there's a profile image file to upload
      if (userData.containsKey('profileImage') &&
          userData['profileImage'] is File) {
        final file = userData['profileImage'] as File;
        final fileName = file.path.split('/').last;

        // Create FormData for file upload
        final formData = FormData.fromMap({
          'name': userData['name'] ?? '',
          'email': userData['email'] ?? '',
          'phoneNumber': userData['phoneNumber'] ?? '',
          'fathersPhoneNumber': userData['fathersPhoneNumber'],
          'mothersPhoneNumber': userData['mothersPhoneNumber'],
          'birthdate': userData['birthdate'],
          'address': userData['address'],
          'addressLocationLink': userData['addressLocationLink'],
          'fatherOfConfession': userData['fatherOfConfession'],
          'profileImage': await MultipartFile.fromFile(
            file.path,
            filename: fileName,
          ),
        });

        final response = await _dio.put('/users/$id', data: formData);
        return response.data;
      } else {
        // Regular update without file upload
        final response = await _dio.put('/users/$id', data: userData);
        return response.data;
      }
    } on DioException catch (e) {
      throw handleError(e);
    }
  }

  /// Update user profile (for khadem to update makhdoum profiles - excludes email and password)
  Future<Map<String, dynamic>> updateUserProfile(
      String id, Map<String, dynamic> profileData) async {
    try {
      final response =
          await _dio.patch('/users/$id/profile', data: profileData);
      return response.data;
    } on DioException catch (e) {
      throw handleError(e);
    }
  }

  // Class Management APIs
  Future<List<dynamic>> getClasses() async {
    try {
      final response = await _dio.get('/classes');
      return response.data;
    } on DioException catch (e) {
      throw handleError(e);
    }
  }

  Future<Map<String, dynamic>> getClassById(String classId) async {
    try {
      final response = await _dio.get('/classes/$classId');
      return response.data;
    } on DioException catch (e) {
      throw handleError(e);
    }
  }

  Future<Map<String, dynamic>> createClass(
      Map<String, dynamic> classData) async {
    try {
      final response = await _dio.post('/classes', data: classData);
      return response.data;
    } on DioException catch (e) {
      throw handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateClass(
      String classId, Map<String, dynamic> classData) async {
    try {
      final response = await _dio.put('/classes/$classId', data: classData);
      return response.data;
    } on DioException catch (e) {
      throw handleError(e);
    }
  }

  Future<void> deleteClass(String classId) async {
    try {
      await _dio.delete('/classes/$classId');
    } on DioException catch (e) {
      throw handleError(e);
    }
  }

  Future<Map<String, dynamic>> getClassMembers(String classId) async {
    try {
      final response = await _dio.get('/classes/$classId/members');
      return response.data;
    } on DioException catch (e) {
      throw handleError(e);
    }
  }

  Future<Map<String, dynamic>> addClassMember(
      String classId, Map<String, dynamic> memberData) async {
    try {
      final response =
          await _dio.post('/classes/$classId/members', data: memberData);
      return response.data;
    } on DioException catch (e) {
      throw handleError(e);
    }
  }

  Future<void> removeClassMember(String classId, String userId) async {
    try {
      await _dio.delete('/classes/$classId/members/$userId');
    } on DioException catch (e) {
      throw handleError(e);
    }
  }

  Future<List<dynamic>> getMyClasses() async {
    try {
      final response = await _dio.get('/classes/my-classes');
      return response.data;
    } on DioException catch (e) {
      throw handleError(e);
    }
  }

  Future<List<dynamic>> getMyMembers() async {
    try {
      final response = await _dio.get('/classes/my-members');
      return response.data;
    } on DioException catch (e) {
      throw handleError(e);
    }
  }

  // Error handling
  @override
  String handleError(DioException error) {
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
