import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/app_theme.dart';
import 'package:smart_rajasthan/i18n/app_locale.dart';
import 'package:smart_rajasthan/screens/raj_sso_native_login_screen.dart';

void main() {
  setUp(() {
    AppLocaleController.instance.setLocaleCode('en', persist: false);
  });

  Widget wrap(Widget child, {Locale? locale}) {
    return MaterialApp(
      locale: locale ?? AppLocaleController.instance.materialLocale,
      theme: buildSmartTheme(),
      home: AppLocaleScope(
        notifier: AppLocaleController.instance,
        child: child,
      ),
    );
  }

  testWidgets('Raj SSO native login shows SSO and password fields in English',
      (tester) async {
    await tester.pumpWidget(wrap(const RajSsoNativeLoginScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('Raj SSO native login shows SSO and password fields in Hindi',
      (tester) async {
    AppLocaleController.instance.setLocaleCode('hi', persist: false);
    await tester.pumpWidget(wrap(const RajSsoNativeLoginScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('साइन इन'), findsOneWidget);
    expect(find.text('SSO ID दर्ज करें'), findsOneWidget);
  });

  testWidgets('Raj SSO native login rebuilds fields after Hindi toggle',
      (tester) async {
    await tester.pumpWidget(wrap(const RajSsoNativeLoginScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Sign In'), findsOneWidget);

    AppLocaleController.instance.setLocaleCode('hi', persist: false);
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('साइन इन'), findsOneWidget);
  });
}
