import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/app_globals.dart';
import 'package:smart_rajasthan/app_navigation.dart';
import 'package:smart_rajasthan/services/auth_service.dart';

import 'helpers/fake_secure_storage.dart';
import 'helpers/jwt_test_utils.dart';

void main() {
  setUp(installFakeSecureStorage);
  tearDown(tearDownFakeSecureStorage);

  testWidgets('replaceWithHome navigates to buildHome when authenticated', (tester) async {
    await AuthService.instance.saveToken(validCitizenJwt());

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: gNavigatorKey,
        home: const Scaffold(body: Text('start')),
      ),
    );

    AppNavigation.buildHome = () => const Scaffold(body: Text('home'));

    AppNavigation.replaceWithHome();
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('replaceWithLogin navigates to buildLogin', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: gNavigatorKey,
        home: const Scaffold(body: Text('start')),
      ),
    );

    AppNavigation.buildLogin = () => const Scaffold(body: Text('login'));

    AppNavigation.replaceWithLogin();
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
  });

  testWidgets('replaceWithHome redirects to login when not authenticated', (tester) async {
    await AuthService.instance.clearToken();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: gNavigatorKey,
        home: const Scaffold(body: Text('start')),
      ),
    );

    AppNavigation.buildHome = () => const Scaffold(body: Text('home'));
    AppNavigation.buildLogin = () => const Scaffold(body: Text('login'));

    AppNavigation.replaceWithHome();
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
    expect(find.text('home'), findsNothing);
  });
}
