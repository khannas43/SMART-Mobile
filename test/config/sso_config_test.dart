import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/config/sso_config.dart';

void main() {
  group('SsoConfig.rajSsoMobileEncryptionKey', () {
    test('returns non-empty key in debug / UAT test runs', () {
      expect(SsoConfig.rajSsoMobileEncryptionKey, isNotEmpty);
    });

    test('application id matches Play Store package for App Links', () {
      expect(SsoConfig.androidApplicationId, 'smart.rajasthan.gov.in');
    });

    test('client id available in debug / UAT test runs', () {
      expect(SsoConfig.rajSsoClientId, isNotEmpty);
    });
  });
}
