import 'package:flutter/material.dart';

import '../../app_navigation.dart';
import '../../app_theme.dart';
import '../../core/app_logger.dart';
import '../../i18n/app_locale.dart';
import '../../models/user_role.dart';
import '../../services/api_error_util.dart';
import '../../services/api_exception.dart';
import '../../services/auth_service.dart';
import '../../services/role/role_context.dart';
import '../../services/role/role_mapping_service.dart';
import '../../services/role/role_resolver.dart';
import '../../services/smart_api_service.dart';
import '../citizen/consent_screen.dart';
import '../citizen/dashboard_screen.dart';
import '../department/dashboard_screen.dart';
import '../reports/report_drilldown_screen.dart';
import '../shared/dept_picker_dialog.dart';
import '../../services/role/department_service.dart';
import '../../widgets/shell/role_shell.dart';

/// Resolves role after login and shows the appropriate shell.
class HomeRouter extends StatefulWidget {
  const HomeRouter({super.key});

  @override
  State<HomeRouter> createState() => _HomeRouterState();
}

class _HomeRouterState extends State<HomeRouter> {
  bool _loading = true;
  Object? _errorCause;

  @override
  void initState() {
    super.initState();
    RoleContext.instance.addListener(_onRoleContextChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    RoleContext.instance.removeListener(_onRoleContextChanged);
    super.dispose();
  }

  void _onRoleContextChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _errorCause = null;
    });

    try {
      final session = AuthService.instance.session;
      if (session == null) {
        AppNavigation.replaceWithLogin();
        return;
      }

      await RoleContext.instance.initialize();

      final mappings = await RoleMappingService.instance.loadMappings(
        session: session,
      );
      await RoleContext.instance.setMappings(mappings);

      final panel = RoleContext.instance.canSwitchPanels
          ? (RoleContext.instance.activePanel ??
              RoleResolver.defaultPanel(mappings))
          : RoleResolver.primaryPanel(
              mappings,
              session: session,
            );
      await RoleContext.instance.switchPanel(panel);

      if (panel == SmartPanel.department) {
        try {
          await _ensureDepartmentSelected();
          await RoleContext.instance.syncDepartmentFromMappedList();
        } catch (e) {
          AppLogger.d(
            'HomeRouter',
            'Department panel unavailable, falling back to citizen: $e',
          );
          await RoleContext.instance.switchPanel(SmartPanel.citizen);
        }
      }

      _loadProfileInBackground(session.ssoId);

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      AppLogger.e('HomeRouter', 'Bootstrap failed: $e');
      if (!mounted) return;
      setState(() {
        _errorCause = e;
        _loading = false;
      });
    }
  }

  void _loadProfileInBackground(String? ssoId) {
    if (ssoId == null || ssoId.isEmpty) return;
    SmartApiService.instance.fetchCitizenProfile(ssoId: ssoId).then(
      (_) {},
      onError: (Object e) {
        AppLogger.d('HomeRouter', 'Profile prefetch skipped: $e');
      },
    );
  }

  String _friendlyError(BuildContext context, Object e) {
    if (e is StateError) return e.message;
    return ApiErrorUtil.friendlyMessage(e);
  }

  Future<void> _ensureDepartmentSelected() async {
    final depts = await DepartmentService.instance.fetchMappedDepartments();
    if (depts.isEmpty) {
      final locale = AppLocaleController.instance;
      throw StateError(
        locale.isHindi
            ? 'आपके SSO खाते से कोई विभाग मैप नहीं है।'
            : 'No department mapped to your SSO account.',
      );
    }

    if (depts.length == 1) {
      await RoleContext.instance.setDepartment(
        id: depts.first.id,
        name: depts.first.name,
      );
    } else if (RoleContext.instance.selectedDeptId == null) {
      if (!mounted) return;
      final picked = await DeptPickerDialog.show(context, depts);
      if (picked == null) {
        await RoleContext.instance.switchPanel(SmartPanel.citizen);
        return;
      }
      await RoleContext.instance.setDepartment(
        id: picked.id,
        name: picked.name,
      );
    }
  }

  Widget _buildShell(SmartPanel panel) {
    return switch (panel) {
      SmartPanel.citizen => RoleShell(
          panel: SmartPanel.citizen,
          tabLabelsEn: const ['Dashboard', 'Consent'],
          tabLabelsHi: const ['डैशबोर्ड', 'सहमति'],
          tabIcons: const [
            Icons.dashboard_rounded,
            Icons.fact_check_outlined,
          ],
          tabBuilder: (i) => switch (i) {
              0 => const CitizenDashboardScreen(),
              _ => const CitizenConsentScreen(),
            },
        ),
      SmartPanel.department => RoleShell(
          panel: SmartPanel.department,
          headerSubtitle: RoleContext.instance.selectedDeptName,
          tabLabelsEn: const ['Dashboard', 'Reports'],
          tabLabelsHi: const ['डैशबोर्ड', 'रिपोर्ट'],
          tabIcons: const [
            Icons.dashboard_rounded,
            Icons.assessment_outlined,
          ],
          tabBuilder: (i) => switch (i) {
              0 => const DepartmentDashboardScreen(),
              _ => const ReportDrilldownScreen(),
            },
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: kPrimaryRoyal),
              const SizedBox(height: 12),
              Text(context.l('Loading your dashboard…', 'डैशबोर्ड लोड हो रहा है…')),
            ],
          ),
        ),
      );
    }

    if (_errorCause != null) {
      final errorMessage = _friendlyError(context, _errorCause!);
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: kMuted.withValues(alpha: 0.8), size: 40),
                const SizedBox(height: 12),
                Text(errorMessage, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _bootstrap,
                  child: Text(context.l('Retry', 'पुनः प्रयास')),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    AuthService.instance.logout();
                    RoleContext.instance.clear();
                    AppNavigation.replaceWithLogin();
                  },
                  child: Text(context.l('Back to Login', 'लॉगिन पर वापस')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final panel = RoleContext.instance.activePanel ?? SmartPanel.citizen;
    return _buildShell(panel);
  }
}
