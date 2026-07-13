import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../i18n/app_locale.dart';

/// Shared loading / error / empty UI for data screens (activity 4.0a).
class DataScreenStates {
  DataScreenStates._();

  static Widget loading({
    EdgeInsets padding = const EdgeInsets.all(24),
  }) {
    return Padding(
      padding: padding,
      child: const Center(child: CircularProgressIndicator(color: kIndigo)),
    );
  }

  static Widget error({
    required BuildContext context,
    required String message,
    required VoidCallback onRetry,
    EdgeInsets margin = const EdgeInsets.only(bottom: 12),
  }) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEAEA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5B4B4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFC0392B), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 11, color: Color(0xFFC0392B), height: 1.4),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(context.l('Retry', 'पुनः प्रयास')),
          ),
        ],
      ),
    );
  }

  static Widget empty({
    required String message,
    EdgeInsets padding = const EdgeInsets.all(20),
    bool card = true,
  }) {
    final child = Text(
      message,
      style: const TextStyle(fontSize: 12, color: kMuted, height: 1.45),
      textAlign: TextAlign.center,
    );
    if (!card) {
      return Padding(padding: padding, child: Center(child: child));
    }
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: child,
    );
  }
}
