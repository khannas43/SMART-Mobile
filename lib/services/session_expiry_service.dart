import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../config/env.dart';
import 'auth_service.dart';

/// Watches JWT [exp] and ends the session when it passes (activity 3.10).
///
/// Complements [GlobalApiErrorInterceptor] (HTTP 401) and [SessionGuard] (UI).
class SessionExpiryService with WidgetsBindingObserver {
  SessionExpiryService._();

  static final SessionExpiryService instance = SessionExpiryService._();

  Timer? _expiryTimer;
  var _attached = false;

  void attach() {
    if (_attached) return;
    _attached = true;
    WidgetsBinding.instance.addObserver(this);
    AuthService.instance.addListener(_onAuthChanged);
    _scheduleExpiryTimer();
  }

  void detach() {
    if (!_attached) return;
    _attached = false;
    WidgetsBinding.instance.removeObserver(this);
    AuthService.instance.removeListener(_onAuthChanged);
    _cancelExpiryTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkExpiryOnResume());
    }
  }

  Future<void> _checkExpiryOnResume() async {
    await AuthService.instance.expireSessionIfNeeded();
    _scheduleExpiryTimer();
  }

  void _onAuthChanged() => _scheduleExpiryTimer();

  void _scheduleExpiryTimer() {
    _cancelExpiryTimer();
    if (!_attached || Env.useMockApi) return;

    final session = AuthService.instance.session;
    if (session == null || session.isExpired) return;

    final delay = timeUntilExpiry(DateTime.now(), session.expiresAt);
    if (delay == null) return;
    if (delay <= Duration.zero) {
      unawaited(AuthService.instance.expireSessionIfNeeded());
      return;
    }

    _expiryTimer = Timer(delay, () {
      unawaited(AuthService.instance.expireSessionIfNeeded());
    });
  }

  void _cancelExpiryTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
  }

  @visibleForTesting
  static Duration? timeUntilExpiry(DateTime now, DateTime? expiresAt) {
    if (expiresAt == null) return null;
    return expiresAt.difference(now);
  }
}
