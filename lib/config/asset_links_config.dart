import 'package:flutter/services.dart';

import 'env.dart';
import 'sso_config.dart';

/// Android App Links `assetlinks.json` bundled in the APK (VAPT evidence).
///
/// **Important:** Google/MobSF verification still requires this file on the web host:
/// `https://<host>/.well-known/assetlinks.json` — deploy from [bundledAssetPath] or
/// `tool/deploy/assetlinks-*.json`.
class AssetLinksConfig {
  AssetLinksConfig._();

  static const prodAssetPath = 'assets/.well-known/assetlinks.json';
  static const uatAssetPath = 'assets/.well-known/assetlinks-uat.json';

  static const androidProdAssetPath = '.well-known/assetlinks.json';
  static const androidUatAssetPath = '.well-known/assetlinks-uat.json';

  /// Flutter asset path for the current [Env.environment].
  static String get bundledAssetPath => switch (Env.environment) {
        AppEnvironment.prod => prodAssetPath,
        AppEnvironment.uat || AppEnvironment.dev => uatAssetPath,
      };

  /// Public HTTPS URL Android verifies during App Link setup / MobSF scan.
  static Uri verificationUri(AppEnvironment env) => switch (env) {
        AppEnvironment.prod => SsoConfig.prodAssetLinksUri,
        AppEnvironment.uat || AppEnvironment.dev => Uri.parse(
            'https://smarttest.rajasthan.gov.in/.well-known/assetlinks.json',
          ),
      };

  /// Loads JSON bundled inside the APK (for infra copy / audit).
  static Future<String> loadBundledJson() =>
      rootBundle.loadString(bundledAssetPath);
}
