import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_navigation.dart';
import '../../app_theme.dart';
import '../../i18n/app_locale.dart';
import '../../services/auth_service.dart';
import '../../services/device_security_service.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bar;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();
    _bar = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    unawaited(_bootstrapAfterSplash());
  }

  Future<void> _bootstrapAfterSplash() async {
    await Future<void>.delayed(const Duration(milliseconds: 2700));
    if (!mounted) return;

    final blocked = await DeviceSecurityService.instance.compromisedDeviceReason();
    if (!mounted) return;
    if (blocked != null) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(context.l('Device not supported', 'डिवाइस समर्थित नहीं')),
          content: Text(blocked),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                if (Platform.isAndroid) {
                  SystemNavigator.pop();
                }
              },
              child: Text(context.l('Exit', 'बाहर निकलें')),
            ),
          ],
        ),
      );
      return;
    }

    final next = AuthService.instance.isAuthenticated
        ? AppNavigation.buildHome?.call() ?? const LoginScreen()
        : const LoginScreen();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kDeptNavy, kDeptNavyMid, Color(0xFF101A45)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', width: 96, height: 96),
                const SizedBox(height: 22),
                const Text(
                  'SMART',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l('Government of Rajasthan', 'राजस्थान सरकार'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 200,
                  child: AnimatedBuilder(
                    animation: _bar,
                    builder: (_, __) => LinearProgressIndicator(
                      value: _bar.value,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(kCitizenOrange),
                      minHeight: 3,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Powered by DoIT&C, Rajasthan',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
