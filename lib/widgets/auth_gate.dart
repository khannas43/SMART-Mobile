import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

typedef LoginScreenBuilder = Widget Function();

/// Blocks home until [AuthService] has a valid JWT.
class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.child,
    required this.loginScreen,
  });

  final Widget child;
  final LoginScreenBuilder loginScreen;

  @visibleForTesting
  static bool allowsHome({required bool isAuthenticated}) => isAuthenticated;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    AuthService.instance.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    if (AuthGate.allowsHome(
      isAuthenticated: AuthService.instance.isAuthenticated,
    )) {
      return widget.child;
    }
    return widget.loginScreen();
  }
}
