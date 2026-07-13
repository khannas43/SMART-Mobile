import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/config/env.dart';

void main() {
  group('Env.resolveEnvironment', () {
    test('debug default is UAT (emulator / ssotest + smarttest)', () {
      expect(
        Env.resolveEnvironment(releaseMode: false, envNameOverride: ''),
        AppEnvironment.uat,
      );
    });

    test('release default is prod', () {
      expect(
        Env.resolveEnvironment(releaseMode: true, envNameOverride: ''),
        AppEnvironment.prod,
      );
    });

    test('SMART_ENV override wins', () {
      expect(
        Env.resolveEnvironment(releaseMode: false, envNameOverride: 'prod'),
        AppEnvironment.prod,
      );
    });
  });

  group('Env.useMockApi', () {
    test('always false — live API only', () {
      expect(Env.useMockApi, isFalse);
      expect(Env.requiresAuth, isTrue);
    });
  });
}
