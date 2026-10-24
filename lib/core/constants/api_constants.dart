import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl.endsWith('/')
          ? _configuredBaseUrl.substring(0, _configuredBaseUrl.length - 1)
          : _configuredBaseUrl;
    }

    if (kIsWeb) {
      return 'https://terminology-nearest-rio-prospect.trycloudflare.com/student_api';
    }

    // Android emulator uses 10.0.2.2. Physical devices need a LAN IP like
    // http://192.168.1.8/student_api, passed via --dart-define=API_BASE_URL=...
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2/student_api';
    }

    return 'http://127.0.0.1/student_api';
  }

  static String get authEndpoint => '$baseUrl/auth.php';
  static String get tasksEndpoint => '$baseUrl/tasks.php';
  static String get quizLogEndpoint => '$baseUrl/quiz_logs.php';
  static String get aiQuizEndpoint => '$baseUrl/generate_quiz.php';
}
