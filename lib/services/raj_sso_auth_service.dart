import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';

import '../config/env.dart';
import '../config/sso_config.dart';
import 'smart_api_client.dart';

/// Parsed deep link / App Link after Raj SSO (activities 3.6–3.7).
class RajSsoCallback {
  const RajSsoCallback({
    required this.uri,
    this.userdetails,
    this.ssoId,
    this.error,
  });

  final Uri uri;
  final String? userdetails;
  final String? ssoId;
  final String? error;

  bool get isSuccess => userdetails != null && userdetails!.isNotEmpty;
}

/// How [RajSsoAuthService.launchSignIn] opened the Raj SSO page (activity 3.5).
enum RajSsoLaunchOutcome {
  /// Chrome Custom Tab opened; await deep link (3.6) or user closes tab.
  customTabOpened,

  /// Caller should push [RajSsoWebLoginScreen].
  webViewRequired,
}

/// Opens Rajasthan SSO sign-in in Chrome Custom Tab or WebView fallback.
class RajSsoAuthService {
  RajSsoAuthService._();

  static final RajSsoAuthService instance = RajSsoAuthService._();

  /// Raj SSO sign-in URL for the current [Env.environment].
  Uri get signInUri => SsoConfig.rajSsoSignInUri(Env.environment);

  /// Whether live API mode can open real Raj SSO (not mock UI).
  static bool get isRajSsoAvailable => !Env.useMockApi;

  /// Returns true when [uri] is the registered mobile SSO callback.
  static bool isCallbackUri(Uri? uri) {
    if (uri == null) return false;

    if (uri.scheme == SsoConfig.callbackScheme &&
        uri.host == SsoConfig.callbackHost) {
      return true;
    }

    if (uri.scheme != 'http' && uri.scheme != 'https') return false;

    for (final env in AppEnvironment.values) {
      final expected = SsoConfig.appLinkUri(env);
      if (uri.scheme == expected.scheme &&
          uri.host == expected.host &&
          uri.path == expected.path) {
        return true;
      }
    }

    return false;
  }

  /// Extracts encrypted `userdetails` from callback query (activity 3.7).
  static RajSsoCallback parseCallbackUri(Uri uri) {
    final params = uri.queryParameters;
    return RajSsoCallback(
      uri: uri,
      userdetails: _firstNonEmpty([
        params['userdetails'],
        params['userDetails'],
        params['token'],
      ]),
      ssoId: _firstNonEmpty([
        params['ssoId'],
        params['sso_id'],
        params['SSO_ID'],
      ]),
      error: _firstNonEmpty([
        params['error'],
        params['error_description'],
        params['message'],
      ]),
    );
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  /// Opens Raj SSO in Chrome Custom Tab; returns [RajSsoLaunchOutcome.webViewRequired]
  /// when Custom Tab is unavailable so the caller can open [RajSsoWebLoginScreen].
  Future<RajSsoLaunchOutcome> launchSignIn({
    SsoBrowserMode? mode,
  }) async {
    final browserMode = mode ?? SsoConfig.preferredBrowserMode;
    final uri = signInUri;
    if (browserMode == SsoBrowserMode.chromeCustomTab) {
      try {
        await launchUrl(
          uri,
          customTabsOptions: CustomTabsOptions(
            colorSchemes: CustomTabsColorSchemes.defaults(
              toolbarColor: Color(0xFF2B4673),
            ),
            shareState: CustomTabsShareState.on,
            urlBarHidingEnabled: true,
            showTitle: true,
          ),
        );
        return RajSsoLaunchOutcome.customTabOpened;
      } catch (e, stack) {
        if (kDebugMode) {
          debugPrint('Raj SSO Custom Tab failed: $e\n$stack');
        }
      }
    }
    return RajSsoLaunchOutcome.webViewRequired;
  }

  /// `POST /api/sso/signout` — ends Raj SSO session server-side (activity 3.9).
  ///
  /// Best-effort: failures are logged but do not block local token clearing.
  Future<void> signOut({required String userdetails}) async {
    final trimmed = userdetails.trim();
    if (trimmed.isEmpty) return;

    try {
      await SmartApiClient.instance.post<dynamic>(
        SsoConfig.signOutPath,
        data: {'userdetails': trimmed},
        options: Options(
          extra: const {
            'skipAuthErrorHandling': true,
            'noRetry': true,
          },
          followRedirects: false,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 500,
        ),
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint(
          'Raj SSO signout failed (local session will still be cleared): $e\n$stack',
        );
      }
    }
  }
}
