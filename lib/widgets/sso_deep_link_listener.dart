import 'package:flutter/material.dart';

/// Keeps [SsoDeepLinkService] alive for the app lifetime (activity 3.6).
///
/// Initialization runs in [main] before [runApp] so deep links are received
/// while the user is on the login screen (not only during splash).
class SsoDeepLinkListener extends StatelessWidget {
  const SsoDeepLinkListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
