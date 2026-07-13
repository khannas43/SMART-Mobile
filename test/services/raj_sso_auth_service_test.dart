import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/config/env.dart';
import 'package:smart_rajasthan/config/sso_config.dart';
import 'package:smart_rajasthan/services/raj_sso_auth_service.dart';

void main() {
  group('RajSsoAuthService', () {
    test('signInUri uses UAT Raj SSO in debug default', () {
      expect(
        RajSsoAuthService.instance.signInUri.toString(),
        SsoConfig.rajSsoSignInUri(Env.environment).toString(),
      );
      expect(
        RajSsoAuthService.instance.signInUri.host,
        'ssotest.rajasthan.gov.in',
      );
      expect(
        RajSsoAuthService.instance.signInUri.toString(),
        'https://ssotest.rajasthan.gov.in/signin?ru=SMART&client=mobile',
      );
    });

    test('isCallbackUri matches custom scheme callback', () {
      final uri = Uri.parse(
        '${SsoConfig.callbackUri}?userdetails=encrypted-token',
      );
      expect(RajSsoAuthService.isCallbackUri(uri), isTrue);
    });

    test('isCallbackUri matches HTTPS app link paths', () {
      final uat = SsoConfig.appLinkUri(AppEnvironment.uat);
      expect(
        RajSsoAuthService.isCallbackUri(
          uat.replace(queryParameters: {'userdetails': 'abc'}),
        ),
        isTrue,
      );
    });

    test('isCallbackUri rejects unrelated URLs', () {
      expect(
        RajSsoAuthService.isCallbackUri(
          Uri.parse('https://sso.rajasthan.gov.in/signin?ru=SMART'),
        ),
        isFalse,
      );
    });

    test('parseCallbackUri extracts userdetails query param', () {
      final callback = RajSsoAuthService.parseCallbackUri(
        Uri.parse('smartrajasthan://sso-callback?userdetails=secret'),
      );
      expect(callback.isSuccess, isTrue);
      expect(callback.userdetails, 'secret');
    });

    test('parseCallbackUri extracts ssoId query param', () {
      final callback = RajSsoAuthService.parseCallbackUri(
        Uri.parse(
          'smartrajasthan://sso-callback?userdetails=secret&ssoId=GOURAV99GOYAL',
        ),
      );
      expect(callback.ssoId, 'GOURAV99GOYAL');
    });

    test('parseCallbackUri extracts error param', () {
      final callback = RajSsoAuthService.parseCallbackUri(
        Uri.parse('smartrajasthan://sso-callback?error=access_denied'),
      );
      expect(callback.isSuccess, isFalse);
      expect(callback.error, 'access_denied');
    });
  });
}
