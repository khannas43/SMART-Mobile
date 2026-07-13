import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_globals.dart';
import 'app_theme.dart';
import 'i18n/app_locale.dart';
import 'widgets/session_guard.dart';
import 'widgets/sso_deep_link_listener.dart';
import 'screens/shared/splash_screen.dart';

/// Root app — locale updates via [AppLocaleController] without remounting the navigator.
class SmartApp extends StatefulWidget {
  const SmartApp({super.key});

  @override
  State<SmartApp> createState() => _SmartAppState();
}

class _SmartAppState extends State<SmartApp> {
  @override
  void initState() {
    super.initState();
    AppLocaleController.instance.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    AppLocaleController.instance.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocaleController.instance;

    return MaterialApp(
      navigatorKey: gNavigatorKey,
      scaffoldMessengerKey: gScaffoldMessengerKey,
      title: 'SMART Rajasthan',
      debugShowCheckedModeBanner: false,
      locale: locale.materialLocale,
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
      builder: (context, child) {
        return AppLocaleScope(
          notifier: AppLocaleController.instance,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SsoDeepLinkListener(
        child: SessionGuard(child: SplashScreen()),
      ),
    );
  }
}
