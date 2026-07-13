import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/services/auth_service.dart';
import 'package:smart_rajasthan/widgets/auth_gate.dart';

import '../helpers/fake_secure_storage.dart';
import '../helpers/jwt_test_utils.dart';

void main() {
  setUp(installFakeSecureStorage);
  tearDown(tearDownFakeSecureStorage);

  group('AuthGate.allowsHome', () {
    test('requires JWT', () {
      expect(AuthGate.allowsHome(isAuthenticated: false), isFalse);
      expect(AuthGate.allowsHome(isAuthenticated: true), isTrue);
    });
  });

  testWidgets('AuthGate shows home when JWT is valid', (tester) async {
    await AuthService.instance.saveToken(validCitizenJwt());

    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          loginScreen: () => const Scaffold(body: Text('login')),
          child: const Scaffold(body: Text('home')),
        ),
      ),
    );

    expect(find.text('home'), findsOneWidget);
    expect(find.text('login'), findsNothing);
  });
}
