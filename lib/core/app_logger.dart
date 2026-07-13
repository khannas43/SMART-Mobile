import 'package:flutter/foundation.dart';

/// Debug-only structured logging for services.
class AppLogger {
  AppLogger._();

  static void d(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  static void e(String tag, String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('[$tag] $message${error != null ? ': $error' : ''}');
    }
  }
}
