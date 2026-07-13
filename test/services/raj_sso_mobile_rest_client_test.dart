import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/services/raj_sso_mobile_rest_client.dart';

void main() {
  group('RajSsoMobileRestClient auth request format', () {
    const payload = {
      'Application': 'SMART',
      'UserName': 'TEST.USER',
      'Password': 'encrypted-value',
    };

    test('Production uses form-urlencoded Content-Type', () {
      expect(RajSsoMobileRestClient.usesFormUrlEncodedAuth(true), isTrue);

      final options =
          RajSsoMobileRestClient.buildAuthRequestOptions(useFormUrlEncoded: true);
      expect(
        options.headers?['Content-Type'],
        'application/x-www-form-urlencoded',
      );

      final data = RajSsoMobileRestClient.buildAuthRequestData(
        payload,
        useFormUrlEncoded: true,
      );
      expect(data, isA<Map<String, String>>());
      expect(data, payload);
    });

    test('UAT keeps JSON Content-Type and body', () {
      expect(RajSsoMobileRestClient.usesFormUrlEncodedAuth(false), isFalse);

      final options =
          RajSsoMobileRestClient.buildAuthRequestOptions(useFormUrlEncoded: false);
      expect(options.headers?['Content-Type'], 'application/json');

      final data = RajSsoMobileRestClient.buildAuthRequestData(
        payload,
        useFormUrlEncoded: false,
      );
      expect(data, jsonEncode(payload));
    });
  });
}
