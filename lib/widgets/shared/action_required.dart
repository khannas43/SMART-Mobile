import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../i18n/app_locale.dart';

class ActionRequired extends StatelessWidget {
  const ActionRequired({super.key});

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kAmberL, kCard],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kAmber.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: kAmber, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l('Action Required', 'कार्रवाई आवश्यक'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l(
                    'Your Jan Aadhaar enrollment is not linked. Update your profile in Raj SSO to access citizen services.',
                    'आपका जन आधार पंजीकरण लिंक नहीं है। नागरिक सेवाओं के लिए Raj SSO में अपनी प्रोफ़ाइल अपडेट करें।',
                  ),
                  style: const TextStyle(fontSize: 12, color: kMuted, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
