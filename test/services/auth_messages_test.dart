import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/services/api_exception.dart';
import 'package:smart_rajasthan/services/auth_messages.dart';

void main() {
  group('AuthMessages.fromLoginException', () {
    test('maps network errors to network message', () {
      final msg = AuthMessages.fromLoginException(
        ApiException(message: 'x', kind: ApiErrorKind.network),
        hindi: false,
      );
      expect(msg, AuthMessages.networkEn);
    });

    test('maps 500 errors to service unavailable', () {
      final msg = AuthMessages.fromLoginException(
        ApiException(message: 'x', statusCode: 503),
        hindi: false,
      );
      expect(msg, AuthMessages.serviceUnavailableEn);
    });

    test('maps JWT mint failures to distinct production message', () {
      final msg = AuthMessages.fromLoginException(
        ApiException(message: AuthMessages.jwtMintFailedEn),
        hindi: false,
      );
      expect(msg, AuthMessages.jwtMintFailedEn);
    });

    test('maps other failures to invalid credentials', () {
      final msg = AuthMessages.fromLoginException(
        ApiException(message: 'User not found'),
        hindi: false,
      );
      expect(msg, AuthMessages.invalidCredentialsEn);
    });

    test('returns Hindi invalid credentials', () {
      final msg = AuthMessages.fromLoginException(
        ApiException(message: 'bad password'),
        hindi: true,
      );
      expect(msg, AuthMessages.invalidCredentialsHi);
    });
  });
}
