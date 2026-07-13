import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/services/raj_sso_auth_service.dart';
import 'package:smart_rajasthan/services/sso_callback_router.dart';
import 'package:smart_rajasthan/services/sso_deep_link_service.dart';
import 'package:smart_rajasthan/services/sso_landing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SsoCallbackRouter.completeLoginOverride = ({
      required String userdetails,
      String? ssoId,
    }) async {
      return SsoLandingResult(token: 'test-token');
    };
  });

  tearDown(() {
    SsoCallbackRouter.completeLoginOverride = null;
    SsoCallbackRouter.clearPending();
  });

  group('SsoDeepLinkService', () {
    test('handleIncomingUri ignores non-callback URLs', () async {
      final service = SsoDeepLinkService.forTest();
      await service.handleIncomingUri(
        Uri.parse('https://sso.rajasthan.gov.in/signin?ru=SMART'),
      );
      expect(SsoCallbackRouter.pendingCallback, isNull);
    });

    test('handleIncomingUri routes callback URIs to router', () async {
      final service = SsoDeepLinkService.forTest();
      await service.handleIncomingUri(
        Uri.parse('smartrajasthan://sso-callback?userdetails=abc123'),
      );
      expect(SsoCallbackRouter.pendingCallback, isNull);
    });

    test('handleIncomingUri deduplicates identical URIs', () async {
      final service = SsoDeepLinkService.forTest();
      final uri = Uri.parse('smartrajasthan://sso-callback?userdetails=once');
      await service.handleIncomingUri(uri);
      SsoCallbackRouter.clearPending();
      await service.handleIncomingUri(uri);
      expect(SsoCallbackRouter.pendingCallback, isNull);
    });
  });

  group('SsoCallbackRouter', () {
    test('handleParsed clears pending after successful exchange', () async {
      await SsoCallbackRouter.handleParsed(
        RajSsoAuthService.parseCallbackUri(
          Uri.parse('smartrajasthan://sso-callback?userdetails=token'),
        ),
      );
      expect(SsoCallbackRouter.pendingCallback, isNull);
    });

    test('handleUri ignores unrelated links', () async {
      await SsoCallbackRouter.handleUri(Uri.parse('https://example.com/'));
      expect(SsoCallbackRouter.pendingCallback, isNull);
    });
  });
}
