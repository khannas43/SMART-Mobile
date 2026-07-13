import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'app_navigation.dart';
import 'i18n/app_locale.dart';
import 'screens/auth/login_screen.dart';
import 'screens/shared/home_router.dart';
import 'services/auth_service.dart';
import 'services/role/role_context.dart';
import 'services/sso_deep_link_service.dart';
import 'widgets/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppNavigation.buildLogin = () => const LoginScreen();
  AppNavigation.buildHome = () => AuthGate(
        loginScreen: () => const LoginScreen(),
        child: const HomeRouter(),
      );

  await AppLocaleService.instance.initialize();
  await AuthService.instance.initialize();
  await RoleContext.instance.initialize();
  await SsoDeepLinkService.instance.initialize();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const SmartApp());
}
