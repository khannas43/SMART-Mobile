import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/services/auth_service.dart';
import 'package:smart_rajasthan/services/session_expiry_service.dart';

import '../helpers/fake_secure_storage.dart';
import '../helpers/jwt_test_utils.dart';

void main() {
  setUp(installFakeSecureStorage);
  tearDown(tearDownFakeSecureStorage);

  group('SessionExpiryService.timeUntilExpiry', () {
    test('returns null when expiresAt is missing', () {
      expect(
        SessionExpiryService.timeUntilExpiry(DateTime.now(), null),
        isNull,
      );
    });

    test('returns negative duration when already expired', () {
      final now = DateTime(2026, 6, 27, 12);
      final expiresAt = now.subtract(const Duration(minutes: 5));
      expect(
        SessionExpiryService.timeUntilExpiry(now, expiresAt),
        equals(const Duration(minutes: -5)),
      );
    });

    test('returns positive duration before expiry', () {
      final now = DateTime(2026, 6, 27, 12);
      final expiresAt = now.add(const Duration(minutes: 15));
      expect(
        SessionExpiryService.timeUntilExpiry(now, expiresAt),
        equals(const Duration(minutes: 15)),
      );
    });
  });

  group('AuthService.expireSessionIfNeeded', () {
    test('ends session when JWT exp has passed while app is open', () async {
      final auth = AuthService.forTest();
      final exp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1;
      final token = buildTestJwt({
        'ssoId': 'TEST.SSO',
        'currentSrole': 'citizen',
        'exp': exp,
      });
      await auth.saveToken(token);
      await Future<void>.delayed(const Duration(seconds: 2));

      final expired = await auth.expireSessionIfNeeded();
      expect(expired, isTrue);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.sessionEndedMessage, isNotNull);
    });

    test('does nothing for valid JWT', () async {
      final auth = AuthService.forTest();
      await auth.saveToken(validCitizenJwt());

      final expired = await auth.expireSessionIfNeeded();
      expect(expired, isFalse);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.sessionEndedMessage, isNull);
    });
  });
}
