import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../i18n/app_locale.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import '../language_switcher.dart';
import '../role_switcher.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.panel,
    this.subtitle,
    this.onLogout,
    this.onPanelChanged,
  });

  final SmartPanel panel;
  final String? subtitle;
  final VoidCallback? onLogout;
  final VoidCallback? onPanelChanged;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  Color get _accent => switch (panel) {
        SmartPanel.citizen => kCitizenOrange,
        SmartPanel.department => kDeptNavyMid,
      };

  String get _displayName {
    final name = AuthService.instance.session?.userName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final ssoId = AuthService.instance.session?.ssoId?.trim();
    if (ssoId != null && ssoId.isNotEmpty) return ssoId;
    return 'User';
  }

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: kText,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: Container(height: 3, color: _accent),
      ),
      title: Row(
        children: [
          Image.asset(
            'assets/icon/icon_foreground.png',
            width: 36,
            height: 36,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 11, color: kMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        RoleSwitcher(onPanelChanged: onPanelChanged),
        const LanguageSwitcher(),
        const SizedBox(width: 4),
        IconButton(
          tooltip: context.l('Logout', 'लॉग आउट'),
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded, color: kMuted),
        ),
      ],
    );
  }
}
