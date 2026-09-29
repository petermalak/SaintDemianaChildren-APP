import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  none,
}

class LoggingService {
  static LoggingService? _instance;
  final List<String> _logBuffer = [];
  final int _maxBufferSize = 200; // Maximum number of log entries to keep

  /// Bodies are trimmed before logging: some responses (attendance, members) are
  /// megabytes of JSON, and printing or buffering them stalls the UI thread.
  static const int _maxBodyChars = 300;

  // Private constructor
  LoggingService._();

  // Singleton instance
  static LoggingService get instance {
    _instance ??= LoggingService._();
    return _instance!;
  }

  // Release builds keep only warnings and errors; debug logging is for development.
  LogLevel get _currentLogLevel =>
      kDebugMode ? LogLevel.debug : LogLevel.warning;

  String _trim(dynamic value) {
    if (value == null) return 'null';
    final text = value is String ? value : value.toString();
    return text.length <= _maxBodyChars
        ? text
        : '${text.substring(0, _maxBodyChars)}… (${text.length} chars)';
  }

  /// Hides the bearer token so it never reaches logs.
  Map<String, dynamic>? _safeHeaders(Map<String, dynamic>? headers) {
    if (headers == null) return null;
    if (!headers.containsKey('Authorization')) return headers;
    return {...headers, 'Authorization': '***'};
  }

  // Check if a log level should be processed
  bool _shouldLog(LogLevel level) {
    return level.index >= _currentLogLevel.index;
  }

  // Add a log entry to the buffer
  void _addToBuffer(String logEntry) {
    if (_logBuffer.length >= _maxBufferSize) {
      _logBuffer.removeAt(0); // Remove oldest log
    }
    _logBuffer.add(logEntry);
  }

  // Get all logs
  List<String> getLogs() {
    return List.from(_logBuffer);
  }

  // Clear logs
  void clearLogs() {
    _logBuffer.clear();
  }

  // Debug level logging
  void debug(String message, {String? tag}) {
    if (!_shouldLog(LogLevel.debug)) return;

    final logEntry = '[DEBUG] ${tag != null ? '[$tag] ' : ''}$message';

    if (kDebugMode) {
      print(logEntry);
    }

    if (kIsWeb) {
      // Web-specific logging
      // ignore: avoid_web_libraries_in_flutter
      developer.log(logEntry);
    }

    _addToBuffer(logEntry);
  }

  // Info level logging
  void info(String message, {String? tag}) {
    if (!_shouldLog(LogLevel.info)) return;

    final logEntry = '[INFO] ${tag != null ? '[$tag] ' : ''}$message';

    if (kDebugMode) {
      print(logEntry);
    }

    if (kIsWeb) {
      // Web-specific logging
      // ignore: avoid_web_libraries_in_flutter
      developer.log(logEntry);
    }

    _addToBuffer(logEntry);
  }

  // Warning level logging
  void warning(String message, {String? tag}) {
    if (!_shouldLog(LogLevel.warning)) return;

    final logEntry = '[WARNING] ${tag != null ? '[$tag] ' : ''}$message';

    if (kDebugMode) {
      print(logEntry);
    }

    if (kIsWeb) {
      // Web-specific logging
      // ignore: avoid_web_libraries_in_flutter
      developer.log(logEntry);
    }

    _addToBuffer(logEntry);
  }

  // Error level logging
  void error(String message,
      {String? tag, Object? error, StackTrace? stackTrace}) {
    if (!_shouldLog(LogLevel.error)) return;

    final errorStr = error != null ? '\nError: ${_trim(error)}' : '';
    final stackStr =
        stackTrace != null && kDebugMode ? '\nStackTrace: $stackTrace' : '';
    final logEntry =
        '[ERROR] ${tag != null ? '[$tag] ' : ''}$message$errorStr$stackStr';

    if (kDebugMode) {
      print(logEntry);
    }

    if (kIsWeb) {
      // Web-specific logging
      // ignore: avoid_web_libraries_in_flutter
      developer.log(logEntry, error: error, stackTrace: stackTrace);
    }

    _addToBuffer(logEntry);
  }

  // Log HTTP request
  void logRequest(String method, String url,
      {Map<String, dynamic>? headers, dynamic body}) {
    if (!_shouldLog(LogLevel.debug)) return;

    final logEntry = '''
[HTTP REQUEST] $method $url
Headers: ${_safeHeaders(headers)}
Body: ${_trim(body)}
'''
        .trim();

    if (kDebugMode) {
      print(logEntry);
    }

    if (kIsWeb) {
      // Web-specific logging
      // ignore: avoid_web_libraries_in_flutter
      developer.log(logEntry);
    }

    _addToBuffer(logEntry);
  }

  // Log HTTP response
  void logResponse(String method, String url, int statusCode,
      {dynamic body, Duration? duration}) {
    if (!_shouldLog(LogLevel.debug)) return;

    final durationStr =
        duration != null ? ' (${duration.inMilliseconds}ms)' : '';
    final logEntry = '''
[HTTP RESPONSE]$durationStr $method $url
Status: $statusCode
Body: ${_trim(body)}
'''
        .trim();

    if (kDebugMode) {
      print(logEntry);
    }

    if (kIsWeb) {
      // Web-specific logging
      // ignore: avoid_web_libraries_in_flutter
      developer.log(logEntry);
    }

    _addToBuffer(logEntry);
  }
}
