import 'package:flutter/material.dart';

import '../../app_navigation.dart';
import '../../app_theme.dart';
import '../../i18n/app_locale.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import '../../services/citizen_navigation.dart';
import '../../services/role/role_context.dart';
import 'app_header.dart';

typedef RoleTabBuilder = Widget Function(int index);

class RoleShell extends StatefulWidget {
  const RoleShell({
    super.key,
    required this.panel,
    required this.tabLabelsEn,
    required this.tabLabelsHi,
    required this.tabIcons,
    required this.tabBuilder,
    this.headerSubtitle,
    this.useDepartmentHeaderSubtitle = false,
  });

  final SmartPanel panel;
  final List<String> tabLabelsEn;
  final List<String> tabLabelsHi;
  final List<IconData> tabIcons;
  final RoleTabBuilder tabBuilder;
  final String? headerSubtitle;

  /// When true, header subtitle listens to [RoleContext.selectedDeptName].
  final bool useDepartmentHeaderSubtitle;

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  int _tab = 0;
  bool _loggingOut = false;

  Color get _accent => switch (widget.panel) {
        SmartPanel.citizen => kCitizenOrange,
        SmartPanel.department => kDeptNavyMid,
      };

  @override
  void initState() {
    super.initState();
    if (widget.panel == SmartPanel.citizen) {
      CitizenNavigation.instance.addListener(_onCitizenNav);
    }
  }

  @override
  void dispose() {
    if (widget.panel == SmartPanel.citizen) {
      CitizenNavigation.instance.removeListener(_onCitizenNav);
    }
    super.dispose();
  }

  void _onCitizenNav() {
    final tab = CitizenNavigation.instance.consumePendingTab();
    if (tab != null && mounted) {
      setState(() => _tab = tab);
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      await AuthService.instance.logout();
      await RoleContext.instance.clear();
      if (!mounted) return;
      AppNavigation.replaceWithLogin();
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);

    Widget shell(String? subtitle) {
      return Scaffold(
        appBar: AppHeader(
          panel: widget.panel,
          subtitle: subtitle,
          onLogout: _loggingOut ? null : _logout,
          onPanelChanged: () => setState(() {}),
        ),
        body: widget.tabBuilder(_tab),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: kBorder)),
            color: kCard,
          ),
          child: BottomNavigationBar(
            currentIndex: _tab,
            onTap: (i) => setState(() => _tab = i),
            selectedItemColor: _accent,
            unselectedItemColor: kMuted,
            items: [
              for (var i = 0; i < widget.tabIcons.length; i++)
                BottomNavigationBarItem(
                  icon: Icon(widget.tabIcons[i]),
                  label: context.l(
                    widget.tabLabelsEn[i],
                    widget.tabLabelsHi[i],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (widget.useDepartmentHeaderSubtitle) {
      return ListenableBuilder(
        listenable: RoleContext.instance,
        builder: (context, _) {
          final name = RoleContext.instance.selectedDeptName?.trim();
          return shell(name != null && name.isNotEmpty ? name : null);
        },
      );
    }

    return shell(widget.headerSubtitle);
  }
}
