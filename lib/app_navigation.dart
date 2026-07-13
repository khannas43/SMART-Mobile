import 'package:flutter/material.dart';

import 'app_globals.dart';
import 'config/env.dart';
import 'services/auth_service.dart';

/// Avoids circular imports between [main.dart] and SSO services (activity 3.7).
abstract class AppNavigation {
  static Widget Function()? buildHome;
  static Widget Function()? buildLogin;

  static void replaceWithHome() {
    if (Env.requiresAuth && !AuthService.instance.isAuthenticated) {
      replaceWithLogin();
      return;
    }

    final build = buildHome;
    if (build == null) return;
    gNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => build()),
      (_) => false,
    );
  }

  static void replaceWithLogin() {
    final build = buildLogin;
    if (build == null) return;
    gNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => build()),
      (_) => false,
    );
  }
}
