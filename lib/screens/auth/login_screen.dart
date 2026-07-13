import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../config/env.dart';
import '../../i18n/app_locale.dart';
import '../raj_sso_native_login_screen.dart';
import '../../widgets/language_switcher.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  String _envLabel(BuildContext context) => switch (Env.environment) {
        AppEnvironment.prod => context.l('Production', 'प्रोडक्शन'),
        AppEnvironment.uat => context.l('UAT', 'UAT'),
        AppEnvironment.dev => context.l('Dev', 'डेव'),
      };

  void _openNativeLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RajSsoNativeLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [kDeptNavy, kDeptNavyMid]),
              border: Border(
                bottom: BorderSide(color: kCitizenOrange, width: 3),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(18, 56, 18, 22),
            child: Row(
              children: [
                _emblem(54),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l('Government of Rajasthan', 'राजस्थान सरकार'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 9,
                          letterSpacing: 2,
                        ),
                      ),
                      const Text(
                        'SMART',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        context.l(
                          'Service Management with Artificial Intelligence and Real-Time System',
                          'कृत्रिम बुद्धिमत्ता एवं रियल-टाइम प्रणाली के साथ सेवा प्रबंधन',
                        ),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 9,
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Text(
                        _envLabel(context),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const LanguageSwitcher(onDark: true),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  _infoBanner(
                    context.l(
                      'Sign in with your Rajasthan SSO ID and password.',
                      'अपनी राजस्थान SSO ID और पासवर्ड से साइन इन करें।',
                    ),
                  ),
                  const SizedBox(height: 18),
                  _LoginPrimaryButton(
                    label: context.l(
                      'Sign in with SSO ID & Password',
                      'SSO ID और पासवर्ड से साइन इन',
                    ),
                    onTap: () => _openNativeLogin(context),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: kBlueL,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: kBlue.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      context.l(
                        'Your SSO ID must be linked with your Jan Aadhaar to use SMART citizen services.',
                        'SMART नागरिक सेवाओं हेतु आपकी SSO ID जन आधार से लिंक होनी चाहिए।',
                      ),
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: kBlue,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginPrimaryButton extends StatelessWidget {
  const _LoginPrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [kPrimaryRoyal, kDeptNavyMid]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.login_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _emblem(double size) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(size * 0.22),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset('assets/logo.png', fit: BoxFit.contain),
    ),
  );
}

Widget _infoBanner(String text) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: kIndigoL,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: kIndigo.withValues(alpha: 0.18)),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        color: kIndigo,
        height: 1.55,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
