/// Runtime environment for SMART mobile API calls.
///
/// **Defaults:**
/// - Debug / emulator (`flutter run`) → **UAT** — ssotest SSO + smarttest backend
/// - Release APK (`flutter build apk --release`) → **prod** unless `SMART_ENV=uat`
library;

import 'package:flutter/foundation.dart';

enum AppEnvironment {
  dev,
  uat,
  prod;

  static AppEnvironment parse(String value) {
    switch (value.trim().toLowerCase()) {
      case 'dev':
      case 'development':
      case 'local':
        return AppEnvironment.dev;
      case 'uat':
      case 'test':
        return AppEnvironment.uat;
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
      default:
        return AppEnvironment.uat;
    }
  }
}

class Env {
  Env._();

  static const String _envNameOverride =
      String.fromEnvironment('SMART_ENV', defaultValue: '');

  static const String _apiHostOverride =
      String.fromEnvironment('SMART_API_HOST', defaultValue: '');

  static AppEnvironment get environment => resolveEnvironment(
        releaseMode: kReleaseMode,
        envNameOverride: _envNameOverride,
      );

  /// Mock API removed — all builds use live backend.
  static bool get useMockApi => false;

  static bool get requiresAuth => true;

  @visibleForTesting
  static AppEnvironment resolveEnvironment({
    required bool releaseMode,
    required String envNameOverride,
  }) {
    if (envNameOverride.trim().isNotEmpty) {
      return AppEnvironment.parse(envNameOverride);
    }
    return releaseMode ? AppEnvironment.prod : AppEnvironment.uat;
  }

  @visibleForTesting
  static bool resolveUseMockApi({
    required bool releaseMode,
    required bool useMockFromDefine,
    AppEnvironment environment = AppEnvironment.uat,
  }) =>
      false;

  static String get apiHostOverride => _apiHostOverride;

  static bool get isDev => environment == AppEnvironment.dev;
  static bool get isUat => environment == AppEnvironment.uat;
  static bool get isProd => environment == AppEnvironment.prod;

  static String get apiOrigin {
    if (_apiHostOverride.isNotEmpty) {
      return _stripTrailingSlash(_apiHostOverride);
    }

    switch (environment) {
      case AppEnvironment.dev:
        return 'http://10.0.2.2:8080';
      case AppEnvironment.uat:
        return 'https://smarttest.rajasthan.gov.in';
      case AppEnvironment.prod:
        return 'https://smart.rajasthan.gov.in';
    }
  }

  static String get baseUrl => '$apiOrigin/smart';

  static String apiPath(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$normalized';
  }

  static String _stripTrailingSlash(String url) {
    if (url.endsWith('/')) {
      return url.substring(0, url.length - 1);
    }
    return url;
  }
}
