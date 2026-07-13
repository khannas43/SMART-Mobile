import 'package:flutter/material.dart';

import '../app_globals.dart';
import '../app_navigation.dart';
import '../services/auth_service.dart';
import '../services/session_expiry_service.dart';

/// Redirects to login when [AuthService.endSession] runs (401 or JWT expiry — 3.10).
class SessionGuard extends StatefulWidget {
  const SessionGuard({super.key, required this.child});

  final Widget child;

  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard> {
  @override
  void initState() {
    super.initState();
    AuthService.instance.addListener(_onAuthChange);
    SessionExpiryService.instance.attach();
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_onAuthChange);
    SessionExpiryService.instance.detach();
    super.dispose();
  }

  void _onAuthChange() {
    final message = AuthService.instance.sessionEndedMessage;
    if (message == null) return;

    AuthService.instance.acknowledgeSessionEnded();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSessionEndedMessage(message);
      AppNavigation.replaceWithLogin();
    });
  }

  @visibleForTesting
  static void showSessionEndedMessage(String message) {
    gScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFC0392B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSessionEndedMessage(String message) =>
      showSessionEndedMessage(message);

  @override
  Widget build(BuildContext context) => widget.child;
}
