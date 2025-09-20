import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'logging_service.dart';

class ApiService {
  static String get baseUrl => AppConfig.apiUrl;
  
  late Dio _dio;
  static ApiService? _instance;
  
  ApiService._() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: AppConfig.connectionTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
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
          final token = await _getStoredToken();
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
          if (error.response?.statusCode == 401) {
            _clearStoredToken();
          }
          
          handler.next(error);
        },
      ),
    );
  }
  
  Future<String?> _getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  Future<void> _storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  Future<void> _clearStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  
  // Authentication endpoints
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      if (response.data['token'] != null) {
        await _storeToken(response.data['token']);
      }
      
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
      await _clearStoredToken();
    } on DioException catch (e) {
      // Even if logout fails on server, clear local token
      await _clearStoredToken();
      throw _handleError(e);
    }
  }
  
  // User endpoints
  Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final response = await _dio.get('/users/me');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> updateMyProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/users/me', data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
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
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getUsers({String? role}) async {
    try {
      final Map<String, dynamic> queryParams = {}; // Explicitly type as Map<String, dynamic>
      if (role != null) queryParams['role'] = role;

      final response = await _dio.get('/users', queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> getUserById(String id) async {
    try {
      final response = await _dio.get('/users/$id');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    // Remove empty id field as it should be generated by the server
    final cleanUserData = Map<String, dynamic>.from(userData);
    cleanUserData.remove('id');
    
    // Remove null or empty profileImage to avoid validation issues
    if (cleanUserData['profileImage'] == null || cleanUserData['profileImage'] == '') {
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
      
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> userData) async {
    try {
      // Check if there's a profile image file to upload
      if (userData.containsKey('profileImage') && userData['profileImage'] is File) {
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
      throw _handleError(e);
    }
  }

  /// Update user profile (for khadem to update makhdoum profiles - excludes email and password)
  Future<Map<String, dynamic>> updateUserProfile(String id, Map<String, dynamic> profileData) async {
    try {
      final response = await _dio.patch('/users/$id/profile', data: profileData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> deleteUser(String id) async {
    try {
      await _dio.delete('/users/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Attendance endpoints
  Future<List<dynamic>> getAttendance({
    String? type,
    String? userId,
    String? date,
  }) async {
    try {
      final Map<String, dynamic> queryParams = <String, dynamic>{}; // Explicit typing
      if (type != null) queryParams['type'] = type;
      if (userId != null) queryParams['userId'] = userId;
      if (date != null) queryParams['date'] = date;
      
      final response = await _dio.get('/attendance', queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> getAttendanceById(String id) async {
    try {
      final response = await _dio.get('/attendance/$id');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> createAttendance(Map<String, dynamic> attendanceData) async {
    try {
      final response = await _dio.post('/attendance', data: attendanceData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> updateAttendance(String id, Map<String, dynamic> attendanceData) async {
    try {
      final response = await _dio.put('/attendance/$id', data: attendanceData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> deleteAttendance(String id) async {
    try {
      await _dio.delete('/attendance/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Error handling
  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'An error occurred';
        
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