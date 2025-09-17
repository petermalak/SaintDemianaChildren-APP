import '../services/logging_service.dart';

class AppConfig {
  // API Configuration
  static const String developmentUrl = 'http://localhost:3000';  // Use localhost for web
  static const String productionUrl = 'https://api.saintdemiana.com';
  
  // Current environment
  static const bool isDevelopment = true; // Change to false for production
  
  // Get current API URL
  static String get apiUrl => isDevelopment ? developmentUrl : productionUrl;
  
  // Logging Configuration
  static LogLevel get logLevel => isDevelopment ? LogLevel.debug : LogLevel.error;
  static const bool enableWebConsole = true; // Enable web console UI for debugging
  
  // App Configuration
  static const String appName = 'Saint Demiana Children';
  static const String appVersion = '1.0.0';
  
  // Timeout configurations
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Demo credentials for testing
  static const Map<String, Map<String, String>> demoCredentials = {
    'admin': {
      'email': 'admin@test.com',
      'password': 'admin123',
    },
    'khadem': {
      'email': 'khadem@test.com',
      'password': 'khadem123',
    },
    'makhdoum': {
      'email': 'makhdoum@test.com',
      'password': 'makhdoum123',
    },
  };
  
  // Web Console Configuration
  static const int webConsoleMaxHeight = 300; // Height in pixels
  static const int webConsoleMaxEntries = 100; // Maximum number of log entries to display
}