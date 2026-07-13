import 'package:flutter/services.dart';

/// Android `FLAG_SECURE` — blocks screenshots/recents on sensitive screens (VAPT).
class ScreenSecurity {
  ScreenSecurity._();

  static const _channel = MethodChannel('gov.rajasthan.smart/screen_security');

  static Future<void> enable() async {
    try {
      await _channel.invokeMethod<void>('enable');
    } on PlatformException {
      // No-op on unsupported platforms.
    }
  }

  static Future<void> disable() async {
    try {
      await _channel.invokeMethod<void>('disable');
    } on PlatformException {
      // No-op on unsupported platforms.
    }
  }
}
