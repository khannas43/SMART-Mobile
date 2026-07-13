import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/app_theme.dart';
import 'package:smart_rajasthan/i18n/app_locale.dart';
import 'package:smart_rajasthan/screens/raj_sso_native_login_screen.dart';

/// Mirrors [SmartApp] locale wiring — delegates are required for hi + TextFormField.
Widget wrapSmartStyle({required bool hindi}) {
  AppLocaleController.instance.setLocaleCode(hindi ? 'hi' : 'en', persist: false);
  return MaterialApp(
    locale: AppLocaleController.instance.materialLocale,
    supportedLocales: const [
      Locale('en', 'IN'),
      Locale('hi', 'IN'),
    ],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: buildSmartTheme(),
    home: AppLocaleScope(
      notifier: AppLocaleController.instance,
      child: const RajSsoNativeLoginScreen(),
    ),
  );
}

void main() {
  testWidgets('Hindi Raj SSO login renders input fields with localization delegates',
      (tester) async {
    await tester.pumpWidget(wrapSmartStyle(hindi: true));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('SSO ID दर्ज करें'), findsOneWidget);
    expect(find.text('पासवर्ड दर्ज करें'), findsOneWidget);
    expect(find.text('साइन इन'), findsOneWidget);
  });
}
