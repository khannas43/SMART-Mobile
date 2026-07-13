import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/config/asset_links_config.dart';
import 'package:smart_rajasthan/config/env.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AssetLinksConfig', () {
    test('bundled prod assetlinks contains package_name', () async {
      final json = await rootBundle.loadString(AssetLinksConfig.prodAssetPath);
      expect(json, contains('smart.rajasthan.gov.in'));
      expect(json, contains('sha256_cert_fingerprints'));
    });

    test('verification URI for prod host', () {
      final uri = AssetLinksConfig.verificationUri(AppEnvironment.prod);
      expect(uri.toString(),
          'https://smart.rajasthan.gov.in/.well-known/assetlinks.json');
    });
  });
}
