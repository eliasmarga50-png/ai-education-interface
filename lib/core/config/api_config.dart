import 'package:flutter/foundation.dart';

/// Where the backends live.
///
/// Override at run time (no code change needed):
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000 \
///               --dart-define=COURSES_API_URL=http://192.168.1.20:3001
///
/// Release builds must use https:// URLs for both.
class ApiConfig {
  ApiConfig._();

  static const String _override = String.fromEnvironment('API_BASE_URL');
  static const String _coursesOverride =
      String.fromEnvironment('COURSES_API_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) {
      return _override;
    }

    // The Android emulator reaches my computer through 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }

    // iOS simulator, desktop and Flutter web.
    return 'http://localhost:3000';
  }

  /// The NestJS course-service (courses and learning resources).
  static String get coursesBaseUrl {
    if (_coursesOverride.isNotEmpty) {
      return _coursesOverride;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3001';
    }

    return 'http://localhost:3001';
  }

  static const Duration timeout = Duration(seconds: 15);
}