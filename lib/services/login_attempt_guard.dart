import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_messages.dart';

/// Client-side login throttling (VAPT — brute-force mitigation).
class LoginAttemptGuard {
  LoginAttemptGuard._();

  static final LoginAttemptGuard instance = LoginAttemptGuard._();

  static const _failCountKey = 'login_fail_count';
  static const _lockedUntilKey = 'login_locked_until_ms';
  static const maxFailures = 5;
  static const lockoutDuration = Duration(minutes: 15);
  static const minAttemptDelay = Duration(seconds: 2);

  @visibleForTesting
  static FlutterSecureStorage storage = const FlutterSecureStorage();

  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  /// Call before each login attempt. Applies delay and enforces lockout.
  Future<LoginAttemptGate> beforeAttempt({required bool hindi}) async {
    if (kDebugMode) {
      await Future<void>.delayed(minAttemptDelay);
      return const LoginAttemptGate.allowed();
    }

    final lockedUntilMs = int.tryParse(
          await storage.read(key: _lockedUntilKey) ?? '',
        ) ??
        0;
    final now = clock();
    if (lockedUntilMs > now.millisecondsSinceEpoch) {
      final remaining = Duration(
        milliseconds: lockedUntilMs - now.millisecondsSinceEpoch,
      );
      return LoginAttemptGate.blocked(
        _lockoutMessage(remaining, hindi: hindi),
      );
    }

    if (lockedUntilMs > 0 && lockedUntilMs <= now.millisecondsSinceEpoch) {
      await _clearLockout();
    }

    await Future<void>.delayed(minAttemptDelay);
    return const LoginAttemptGate.allowed();
  }

  Future<void> recordFailure() async {
    if (kDebugMode) return;

    final count =
        (int.tryParse(await storage.read(key: _failCountKey) ?? '') ?? 0) + 1;
    await storage.write(key: _failCountKey, value: count.toString());
    if (count >= maxFailures) {
      final until = clock().add(lockoutDuration);
      await storage.write(
        key: _lockedUntilKey,
        value: until.millisecondsSinceEpoch.toString(),
      );
      await storage.write(key: _failCountKey, value: '0');
    }
  }

  Future<void> recordSuccess() async {
    if (kDebugMode) return;
    await _clearLockout();
  }

  Future<void> _clearLockout() async {
    await storage.delete(key: _failCountKey);
    await storage.delete(key: _lockedUntilKey);
  }

  static String _lockoutMessage(Duration remaining, {required bool hindi}) {
    final minutes = remaining.inMinutes.clamp(1, 999);
    if (hindi) {
      return 'बहुत अधिक असफल प्रयास। $minutes मिनट बाद पुनः प्रयास करें।';
    }
    return 'Too many failed attempts. Try again in $minutes minute(s).';
  }
}

class LoginAttemptGate {
  const LoginAttemptGate._({required this.allowed, this.blockMessage});

  const LoginAttemptGate.allowed() : this._(allowed: true);

  const LoginAttemptGate.blocked(String message)
      : this._(allowed: false, blockMessage: message);

  final bool allowed;
  final String? blockMessage;
}
