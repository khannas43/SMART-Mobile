import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../i18n/app_locale.dart';
import '../platform/screen_security.dart';
import '../services/api_error_presenter.dart';
import '../services/api_exception.dart';
import '../services/auth_messages.dart';
import '../services/login_attempt_guard.dart';
import '../services/raj_sso_mobile_auth_service.dart';
import '../widgets/language_switcher.dart';

/// In-app Raj SSO login via REST API Mobile v2.6.1 (`SSOAuthenticationMobileNew`).
class RajSsoNativeLoginScreen extends StatefulWidget {
  const RajSsoNativeLoginScreen({super.key});

  @override
  State<RajSsoNativeLoginScreen> createState() => _RajSsoNativeLoginScreenState();
}

class _RajSsoNativeLoginScreenState extends State<RajSsoNativeLoginScreen> {
  final _ssoIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var _loading = false;
  var _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    ScreenSecurity.enable();
  }

  @override
  void dispose() {
    ScreenSecurity.disable();
    _ssoIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !(_formKey.currentState?.validate() ?? false)) return;

    final hindi = AppLocaleController.instance.isHindi;
    final gate = await LoginAttemptGuard.instance.beforeAttempt(hindi: hindi);
    if (!gate.allowed) {
      ApiErrorPresenter.show(
        ApiException(message: gate.blockMessage ?? AuthMessages.invalidCredentials(hindi: hindi)),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await RajSsoMobileAuthService.instance.loginAndNavigateHome(
        ssoId: _ssoIdController.text.trim(),
        password: _passwordController.text,
      );
      await LoginAttemptGuard.instance.recordSuccess();
    } on ApiException catch (e) {
      await LoginAttemptGuard.instance.recordFailure();
      ApiErrorPresenter.show(
        ApiException(message: AuthMessages.fromLoginException(e, hindi: hindi)),
      );
    } catch (e) {
      await LoginAttemptGuard.instance.recordFailure();
      ApiErrorPresenter.show(
        ApiException(
          message: AuthMessages.invalidCredentials(hindi: hindi),
          cause: e,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kInk,
        foregroundColor: Colors.white,
        title: Text(context.l('Raj SSO Sign In', 'Raj SSO साइन इन')),
        actions: const [LanguageSwitcher(), SizedBox(width: 8)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.isHindi
                    ? 'SSO आईडी'
                    : context.l('SSO ID', 'SSO आईडी').toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: kMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                key: ValueKey('sso-id-${AppLocaleController.instance.localeCode}'),
                controller: _ssoIdController,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                style: const TextStyle(color: kText, fontSize: 15),
                decoration: _fieldDecoration(
                  hint: context.l('Enter SSO ID', 'SSO ID दर्ज करें'),
                  icon: Icons.person_outline_rounded,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.l('SSO ID required', 'SSO ID आवश्यक')
                    : null,
              ),
              const SizedBox(height: 14),
              Text(
                context.isHindi
                    ? 'पासवर्ड'
                    : context.l('Password', 'पासवर्ड').toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: kMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                key: ValueKey('sso-password-${AppLocaleController.instance.localeCode}'),
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: kText, fontSize: 15),
                onFieldSubmitted: (_) => _submit(),
                decoration: _fieldDecoration(
                  hint: context.l('Enter password', 'पासवर्ड दर्ज करें'),
                  icon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: kMuted,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? context.l('Password required', 'पासवर्ड आवश्यक')
                    : null,
              ),
              const SizedBox(height: 22),
              _PrimaryButton(
                loading: _loading,
                label: context.l('Sign In', 'साइन इन'),
                onTap: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: kMuted),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kIndigo, width: 1.5),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.loading,
    required this.label,
    required this.onTap,
  });

  final bool loading;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: loading
                ? [kMuted, kMuted.withValues(alpha: 0.85)]
                : const [kIndigo, kInk2],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              const Icon(Icons.login_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              loading
                  ? context.l('Signing in…', 'साइन इन…')
                  : label,
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
