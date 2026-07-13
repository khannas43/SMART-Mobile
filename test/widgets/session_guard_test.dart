import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/app_globals.dart';
import 'package:smart_rajasthan/app_navigation.dart';
import 'package:smart_rajasthan/services/auth_service.dart';
import 'package:smart_rajasthan/widgets/session_guard.dart';

import '../helpers/fake_secure_storage.dart';
import '../helpers/jwt_test_utils.dart';

void main() {
  setUp(installFakeSecureStorage);
  tearDown(tearDownFakeSecureStorage);

  testWidgets('SessionGuard navigates to login after endSession', (tester) async {
    AppNavigation.buildLogin = () => const Scaffold(body: Text('login'));

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: gNavigatorKey,
        scaffoldMessengerKey: gScaffoldMessengerKey,
        home: const SessionGuard(
          child: Scaffold(body: Text('home')),
        ),
      ),
    );

    await AuthService.instance.saveToken(validCitizenJwt());
    await AuthService.instance.endSession(message: 'Session expired on server');
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
    expect(find.text('home'), findsNothing);
    expect(find.text('Session expired on server'), findsOneWidget);
  });
}
