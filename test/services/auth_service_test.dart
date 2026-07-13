import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/services/auth_service.dart';

import '../helpers/fake_secure_storage.dart';
import '../helpers/jwt_test_utils.dart';

void main() {
  setUp(installFakeSecureStorage);
  tearDown(tearDownFakeSecureStorage);

  group('AuthService', () {
    test('saveToken persists JWT and exposes claims', () async {
      final auth = AuthService.forTest();
      final token = validCitizenJwt(ssoId: 'CITIZEN.SSO', smUserId: '999');

      await auth.saveToken(token);

      expect(auth.isAuthenticated, isTrue);
      expect(auth.accessToken, token);
      expect(auth.ssoId, 'CITIZEN.SSO');
      expect(auth.smUserId, '999');
      expect(auth.currentRole, 'CITIZEN');
      expect(await auth.hasStoredToken(), isTrue);
    });

    test('initialize loads token from secure storage', () async {
      final auth = AuthService.forTest();
      final token = validCitizenJwt();
      await auth.saveToken(token);

      final reloaded = AuthService.forTest();
      await reloaded.initialize();

      expect(reloaded.isAuthenticated, isTrue);
      expect(reloaded.ssoId, auth.ssoId);
    });

    test('clearToken removes session and storage', () async {
      final auth = AuthService.forTest();
      await auth.saveToken(validCitizenJwt());

      await auth.clearToken();

      expect(auth.isAuthenticated, isFalse);
      expect(auth.accessToken, isNull);
      expect(await auth.hasStoredToken(), isFalse);
    });

    test('expired token is rejected on save', () async {
      final auth = AuthService.forTest();
      await auth.saveToken(expiredJwt());

      expect(auth.isAuthenticated, isFalse);
      expect(await auth.hasStoredToken(), isFalse);
    });

    test('endSession clears auth and stores user message', () async {
      final auth = AuthService.forTest();
      await auth.saveToken(validCitizenJwt());

      await auth.endSession(message: 'Session expired on server');

      expect(auth.isAuthenticated, isFalse);
      expect(auth.sessionEndedMessage, 'Session expired on server');
    });

    test('logout clears session without sessionEndedMessage', () async {
      final auth = AuthService.forTest();
      await auth.saveToken(validCitizenJwt());
      await auth.endSession(message: 'Expired');
      auth.acknowledgeSessionEnded();

      await auth.saveToken(validCitizenJwt());
      await auth.logout();

      expect(auth.isAuthenticated, isFalse);
      expect(auth.sessionEndedMessage, isNull);
    });

    test('userdetailsForSignOut reads JWT sub claim', () async {
      final auth = AuthService.forTest();
      await auth.saveToken(validCitizenJwt(sub: 'sso-encrypted-payload'));

      expect(auth.userdetailsForSignOut, 'sso-encrypted-payload');
    });

    test('notifyListeners fires on token changes', () async {
      final auth = AuthService.forTest();
      var notifications = 0;
      auth.addListener(() => notifications++);

      await auth.saveToken(validCitizenJwt());
      await auth.clearToken();

      expect(notifications, greaterThanOrEqualTo(2));
    });
  });
}
