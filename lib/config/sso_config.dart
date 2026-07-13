/// Rajasthan SSO URLs and mobile callback constants (activity 3.1).
///
/// Full design: `tool/MOBILE_SSO_DESIGN.md`
library;

import 'package:flutter/foundation.dart';

import 'env.dart';

/// How the app opens the Raj SSO sign-in page (activity 3.5).
enum SsoBrowserMode {
  /// Recommended for production — shared Chrome profile, visible URL bar.
  chromeCustomTab,

  /// Fallback only (e.g. Custom Tab unavailable). Not preferred for prod.
  inAppWebView,
}

class SsoConfig {
  SsoConfig._();

  /// Play Store / device applicationId (activity 1.5).
  static const String androidApplicationId = 'smart.rajasthan.gov.in';

  /// Kotlin/Java namespace in `android/app/build.gradle.kts`.
  static const String androidNamespace = 'gov.rajasthan.smart';

  /// Registered with Raj SSO team (activity 3.2). Custom URI scheme for callback.
  static const String callbackScheme = 'smartrajasthan';

  static const String callbackHost = 'sso-callback';

  /// Deep link the app listens for after Raj SSO (activity 3.6).
  /// Example: `smartrajasthan://sso-callback?userdetails=...`
  static Uri get callbackUri =>
      Uri(scheme: callbackScheme, host: callbackHost);

  /// All redirect URIs to register with Raj SSO / infra (activity 3.2).
  /// See `tool/SSO_REDIRECT_URI_REGISTRATION.md`.
  static List<String> get registrationRedirectUris => [
        callbackUri.toString(),
        appLinkUri(AppEnvironment.uat).toString(),
        appLinkUri(AppEnvironment.prod).toString(),
      ];

  /// Optional HTTPS App Link path (requires `assetlinks.json` on prod host).
  static const String appLinkPath = '/mobile/sso-callback';

  static Uri appLinkUri(AppEnvironment env) {
    final origin = switch (env) {
      AppEnvironment.prod => 'https://smart.rajasthan.gov.in',
      AppEnvironment.uat => 'https://smarttest.rajasthan.gov.in',
      AppEnvironment.dev => Env.apiOrigin,
    };
    return Uri.parse('$origin$appLinkPath');
  }

  /// Raj SSO sign-in entry (mirrors web `NEXT_PUBLIC_RAJSSO_URL`).
  static Uri rajSsoSignInUri(AppEnvironment env) {
    final base = switch (env) {
      AppEnvironment.prod => 'https://sso.rajasthan.gov.in/signin',
      AppEnvironment.uat || AppEnvironment.dev =>
        'https://ssotest.rajasthan.gov.in/signin',
    };
    return Uri.parse('$base?ru=SMART&client=mobile');
  }

  /// Raj SSO REST API base (Mobile v2.6.1) — port 4443.
  static String rajSsoRestOrigin(AppEnvironment env) => switch (env) {
        AppEnvironment.prod => 'https://sso.rajasthan.gov.in:4443',
        AppEnvironment.uat || AppEnvironment.dev =>
          'https://ssotest.rajasthan.gov.in:4443',
      };

  /// `SSOAuthenticationMobileNew` path (§2.1).
  static const String ssoAuthenticationMobileNewPath =
      '/SSOREST/SSOAuthenticationMobileNew';

  /// Application name registered with Raj SSO for mobile REST auth.
  static const String rajSsoMobileApplicationName = 'SMART';

  /// Encryption key for mobile REST password (v2.6.1 §3).
  ///
  /// Override at compile time with `--dart-define=RAJ_SSO_MOBILE_KEY=...` when Raj SSO
  /// issues a dedicated production key. Until then, prod uses the same Raj SSO mobile key as UAT.
  static const String _rajSsoMobileEncryptionKeyFromDefine = String.fromEnvironment(
    'RAJ_SSO_MOBILE_KEY',
    defaultValue: '',
  );

  /// Shared Raj SSO mobile REST key (UAT + prod until separate prod key is issued).
  static const String _rajSsoMobileEncryptionKeyDefault = r'R@j$S0@02{09}19#';

  static String get rajSsoMobileEncryptionKey {
    if (_rajSsoMobileEncryptionKeyFromDefine.isNotEmpty) {
      return _rajSsoMobileEncryptionKeyFromDefine;
    }
    return _rajSsoMobileEncryptionKeyDefault;
  }

  /// SMART backend: mint JWT after successful Raj SSO REST auth.
  static const String mobileRestLoginPath = '/api/sso/mobile-rest-login';

  static Uri ssoAuthenticationMobileNewUri(AppEnvironment env) => Uri.parse(
        '${rajSsoRestOrigin(env)}$ssoAuthenticationMobileNewPath',
      );

  /// SMART client id registered with Raj SSO (web `.env` `NEXT_PUBLIC_CLIENT_ID`).
  ///
  /// Override with `--dart-define=RAJ_SSO_CLIENT_ID=...` when prod client id differs.
  static const String _rajSsoClientIdFromDefine = String.fromEnvironment(
    'RAJ_SSO_CLIENT_ID',
    defaultValue: '',
  );

  /// Shared SMART client id (UAT + prod).
  static const String _rajSsoClientIdDefault = 'd6tfF2bB6nAFv3depxXsddMbzpOsQSx2';

  static String get rajSsoClientId {
    if (_rajSsoClientIdFromDefine.isNotEmpty) {
      return _rajSsoClientIdFromDefine;
    }
    return _rajSsoClientIdDefault;
  }

  /// Backend paths (relative to [Env.baseUrl]).
  static const String landingPath = '/api/sso/landing';
  static const String sandboxLandingPath = '/api/sso/sandboxlanding';
  static const String sandboxTokenPath = '/api/sso/getSandBoxToken';
  static const String signOutPath = '/api/sso/signout';

  /// JSON token endpoint (activity 3.3 — app receives JWT after deep link).
  static const String mobileLandingPath = '/api/sso/mobile-landing';

  /// Raj SSO POST landing (web + mobile). Mobile: same path with {@code client=mobile}.
  static const String rajSsoPostLandingPath = landingPath;

  /// SSO landing path for [env] (prod → `/landing`, UAT/dev → `/sandboxlanding`).
  static String landingPathFor(AppEnvironment env) =>
      env == AppEnvironment.prod ? landingPath : sandboxLandingPath;

  /// Landing path for the current [Env.environment].
  static String get activeLandingPath => landingPathFor(Env.environment);

  /// Production API origin (no `/smart` suffix).
  static const String prodApiOrigin = 'https://smart.rajasthan.gov.in';

  /// Production Raj SSO sign-in host.
  static const String prodRajSsoHost = 'sso.rajasthan.gov.in';

  /// Android App Link verification file (activity 3.2 / 3.12 PC-08).
  static Uri get prodAssetLinksUri =>
      Uri.parse('$prodApiOrigin/.well-known/assetlinks.json');

  static Uri landingUrl({required bool sandbox}) {
    final path = sandbox ? sandboxLandingPath : landingPath;
    return Uri.parse(Env.apiPath(path));
  }

  static SsoBrowserMode get preferredBrowserMode => SsoBrowserMode.chromeCustomTab;

  /// Whether release builds may use sandbox token shortcut (activity 3.4 / 3.8).
  static bool get allowSandboxTokenInRelease => false;
}
