import 'package:dio/dio.dart';

/// Web-safe implementation: no dart:io. Uses a simple HTTP request to check connectivity.
Future<bool> checkNetworkConnectivity() async {
  try {
    final response = await Dio().get(
      'https://www.google.com',
      options: Options(
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
      ),
    );
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}
