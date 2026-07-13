import 'package:flutter/material.dart';

import '../app_globals.dart';
import 'api_exception.dart';

/// Shows user-visible feedback for API failures (403 ACL, network, etc.).
class ApiErrorPresenter {
  ApiErrorPresenter._();

  static void show(ApiException error) {
    if (error.isUnauthorized) {
      // Session guard in main.dart handles 401 navigation/snackbar.
      return;
    }

    final messenger = gScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(error.message),
        backgroundColor: error.isForbidden ? const Color(0xFFC0392B) : const Color(0xFF2B4673),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
