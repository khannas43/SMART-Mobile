import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../i18n/app_locale.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import '../department_header_switcher.dart';
import '../language_switcher.dart';
import '../role_switcher.dart';

/// Post-login header: logo + full SSO ID on row 1; existing role / language /
/// logout controls on row 2 (same widgets and behavior as before).
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.panel,
    this.subtitle,
    this.onLogout,
    this.onPanelChanged,
    this.showDepartmentSwitcher = false,
  });

  final SmartPanel panel;
  final String? subtitle;
  final VoidCallback? onLogout;
  final VoidCallback? onPanelChanged;

  /// When true (Department panel + Department role), show dept name/dropdown.
  final bool showDepartmentSwitcher;

  static const double _row1Height = 64;
  static const double _row2Height = 48;
  static const double _accentHeight = 3;

  @override
  Size get preferredSize =>
      const Size.fromHeight(_row1Height + _row2Height + _accentHeight);

  Color get _accent => switch (panel) {
        SmartPanel.citizen => kCitizenOrange,
        SmartPanel.department => kDeptNavyMid,
      };

  String get _ssoId {
    final ssoId = AuthService.instance.session?.ssoId?.trim();
    if (ssoId != null && ssoId.isNotEmpty) return ssoId;
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    return Material(
      color: Colors.white,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: _row1Height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/icon/icon_foreground.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              _ssoId,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: kText,
                                height: 1.2,
                              ),
                              softWrap: false,
                            ),
                          ),
                          if (showDepartmentSwitcher)
                            const DepartmentHeaderSwitcher()
                          else if (subtitle != null && subtitle!.isNotEmpty)
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
              ),
            ),
            SizedBox(
              height: _row2Height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: RoleSwitcher(onPanelChanged: onPanelChanged),
                      ),
                    ),
                    const LanguageSwitcher(),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: context.l('Logout', 'लॉग आउट'),
                      onPressed: onLogout,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.logout_rounded, color: kMuted),
                    ),
                  ],
                ),
              ),
            ),
            Container(height: _accentHeight, color: _accent),
          ],
        ),
      ),
    );
  }
}
