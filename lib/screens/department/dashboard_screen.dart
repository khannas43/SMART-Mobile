import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../core/app_logger.dart';
import '../../i18n/app_locale.dart';
import '../../models/user_role.dart';
import '../../services/api_error_util.dart';
import '../../services/api_exception.dart';
import '../../services/dashboard/dashboard_service.dart';
import '../../services/role/role_context.dart';
import '../../widgets/data_screen_states.dart';
import '../../widgets/shell/stat_card.dart';

class DepartmentDashboardScreen extends StatefulWidget {
  const DepartmentDashboardScreen({super.key});

  @override
  State<DepartmentDashboardScreen> createState() =>
      _DepartmentDashboardScreenState();
}

class _DepartmentDashboardScreenState extends State<DepartmentDashboardScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = const {};
  String? _loadedDeptId;
  var _loadGeneration = 0;
  var _loadInFlight = false;
  Timer? _roleDebounce;

  @override
  void initState() {
    super.initState();
    RoleContext.instance.addListener(_onRoleChanged);
    _load();
  }

  @override
  void dispose() {
    _roleDebounce?.cancel();
    RoleContext.instance.removeListener(_onRoleChanged);
    super.dispose();
  }

  void _onRoleChanged() {
    if (!mounted) return;
    // Avoid firing MappedDept / counts while leaving the department panel
    // (panel switch would otherwise surface a spurious "Invalid Request").
    if (RoleContext.instance.activePanel != SmartPanel.department) return;
    final deptId = RoleContext.instance.selectedDeptId;
    if (deptId == _loadedDeptId && !_loading) return;
    _roleDebounce?.cancel();
    _roleDebounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    if (_loadInFlight) return;
    if (RoleContext.instance.activePanel != SmartPanel.department) return;
    _loadInFlight = true;
    final generation = ++_loadGeneration;

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      await RoleContext.instance.syncDepartmentFromMappedList();
      if (RoleContext.instance.activePanel != SmartPanel.department) return;
      final deptId = RoleContext.instance.selectedDeptId;

      if (deptId == null || deptId == '0') {
        if (!mounted || generation != _loadGeneration) return;
        setState(() {
          _data = const {};
          _loadedDeptId = null;
          _loading = false;
          _error = null;
        });
        return;
      }

      final data = DashboardService.unwrapDashboardData(
        await DashboardService.instance.fetchDepartmentCounts(
          departmentId: deptId,
        ),
      );
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _data = data;
        _loadedDeptId = deptId;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      AppLogger.e(
        'DepartmentDashboard',
        'commonDashboardCount failed (deptId=${RoleContext.instance.selectedDeptId})',
        e,
      );
      if (!mounted || generation != _loadGeneration) return;
      // Never show raw "Internal Server Error"; always keep KPI cards at 0.
      final api = ApiErrorUtil.asApiException(e);
      final hideBanner = api.kind == ApiErrorKind.server ||
          api.message == ApiException.serverErrorMessage ||
          (api.statusCode != null && api.statusCode! >= 500);
      setState(() {
        _data = const {};
        _loadedDeptId = RoleContext.instance.selectedDeptId;
        _error = hideBanner
            ? null
            : context.l(
                'Unable to load dashboard counts. Showing zeros.',
                'डैशबोर्ड गणना लोड नहीं हो सकी। शून्य दिखाए जा रहे हैं।',
              );
        _loading = false;
      });
    } finally {
      _loadInFlight = false;
    }
  }

  String _val(String key) => DashboardService.stringValue(_data, key);

  Widget _kpiSection() {
    return StatSection(
      titleEn: 'Overview',
      titleHi: 'अवलोकन',
      cards: [
        StatCardData(
          labelEn: 'Total Schemes & Services',
          labelHi: 'कुल योजनाएं और सेवाएं',
          value: _val('TOTAL_SERVICE'),
          icon: Icons.list_alt_outlined,
          color: Colors.indigo.shade700,
          bgColor: Colors.indigo.shade50,
          barColor: Colors.indigo.shade500,
        ),
        StatCardData(
          labelEn: 'Total Beneficiaries',
          labelHi: 'कुल लाभार्थी',
          value: _val('TOTAL_BENEFICIARY'),
          icon: Icons.groups_outlined,
          color: Colors.orange.shade700,
          bgColor: Colors.orange.shade50,
          barColor: Colors.orange.shade500,
        ),
        StatCardData(
          labelEn: 'Unique Beneficiaries',
          labelHi: 'अद्वितीय लाभार्थी',
          value: _val('UNIQUE_BENEFICIARY'),
          icon: Icons.person_search_outlined,
          color: Colors.teal.shade700,
          bgColor: Colors.teal.shade50,
          barColor: Colors.teal.shade500,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    final deptName = RoleContext.instance.selectedDeptName;

    return RefreshIndicator(
      onRefresh: _load,
      color: kDeptNavyMid,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            context.l('Department Dashboard', 'विभाग डैशबोर्ड'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: kText,
            ),
          ),
          if (deptName != null && deptName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(deptName, style: const TextStyle(fontSize: 13, color: kMuted)),
          ],
          const Divider(height: 24),
          if (_loading)
            DataScreenStates.loading()
          else ...[
            if (_error != null) ...[
              DataScreenStates.error(
                context: context,
                message: _error!,
                onRetry: _load,
              ),
              const SizedBox(height: 16),
            ],
            _kpiSection(),
          ],
        ],
      ),
    );
  }
}
