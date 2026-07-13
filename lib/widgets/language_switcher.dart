import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../i18n/app_locale.dart';

/// Web-style language switcher (shows current label: English / हिंदी).
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key, this.onDark = false});

  final bool onDark;

  static const _languages = [
    (code: 'en', label: 'English'),
    (code: 'hi', label: 'हिंदी'),
  ];

  @override
  Widget build(BuildContext context) {
    final locale = AppLocaleScope.watch(context);
    final fg = onDark ? Colors.white : kText;
    final border = onDark
        ? Colors.white.withValues(alpha: 0.35)
        : kBorder;
    final currentLabel = locale.isHindi ? 'हिंदी' : 'English';

    return PopupMenuButton<String>(
      tooltip: context.l('Change language', 'भाषा बदलें'),
      onSelected: locale.setLocaleCode,
      itemBuilder: (_) => [
        for (final lang in _languages)
          PopupMenuItem(
            value: lang.code,
            child: Row(
              children: [
                if (locale.localeCode == lang.code)
                  Icon(Icons.check, size: 16, color: onDark ? kDeptNavy : kPrimaryRoyal)
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 8),
                Text(lang.label),
              ],
            ),
          ),
      ],
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(8),
          color: onDark ? Colors.transparent : Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              currentLabel,
              style: TextStyle(
                color: fg,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: fg, size: 18),
          ],
        ),
      ),
    );
  }
}
