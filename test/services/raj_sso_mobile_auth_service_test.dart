import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/models/raj_sso_mobile_auth_result.dart';
import 'package:smart_rajasthan/services/raj_sso_mobile_auth_service.dart';

void main() {
  group('RajSsoMobileAuthService', () {
    test('synthetic userdetails are not treated as encrypted SSO tokens', () {
      expect(
        RajSsoMobileAuthService.isEncryptedSsoUserdetailsForTest('mobile-rest:USER'),
        isFalse,
      );
      expect(
        RajSsoMobileAuthService.isEncryptedSsoUserdetailsForTest('sandbox'),
        isFalse,
      );
    });
  });

  test('fromJson ignores short generic token field', () {
    final result = RajSsoMobileAuthResult.fromJson({
      'valid': true,
      'message': 'Login successful',
      'SSOID': 'TEST.USER',
      'token': 'abc123',
    });
    expect(result.landingUserdetails, isNull);
  });

  test('fromJson keeps long encrypted userdetails', () {
    const blob = 'c21SZExWMGVENDd3czBPSjFkeHpZcmxRdkRwZXBva25zZmRJWFc4SGZ5VitTNW16bU9XY2M1NGhmV2dZV29wQXFPOXk0NVFoUlFSWGtwVUx2b1ovUVRFYldSSkwybERNem1PWU9FY0dIQ2w0RFk4ekVoc0lBSkVWblpUZmRvNDhoUnBEUXpncllUQUhJRDJ1MHlEQ1JLYVhaTkpvRVdyMHBQVXRaSmpEeTA4T2dGZTJ6aGJpNHIxbkU3YmZYMDhK';
    final result = RajSsoMobileAuthResult.fromJson({
      'valid': true,
      'userdetails': blob,
      'SSOID': 'TEST.USER',
    });
    expect(result.landingUserdetails, blob);
  });
}
