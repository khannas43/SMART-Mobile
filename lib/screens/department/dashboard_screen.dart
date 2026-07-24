import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../config/env.dart';
import '../../core/app_logger.dart';
import '../../i18n/app_locale.dart';
import '../../models/user_role.dart';
import '../../services/api_error_util.dart';
import '../../services/dashboard/dashboard_service.dart';
import '../../services/role/department_service.dart';
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
  String? _selectDeptHint;
  Map<String, dynamic> _data = const {};
  String? _loadedDeptId;
  var _loadGeneration = 0;
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
    // Reload when dept changes, or when a prior load failed (_loadedDeptId null).
    if (deptId != null &&
        deptId == _loadedDeptId &&
        !_loading &&
        _error == null) {
      return;
    }
    _roleDebounce?.cancel();
    _roleDebounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    if (RoleContext.instance.activePanel != SmartPanel.department) return;
    final generation = ++_loadGeneration;

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
        _selectDeptHint = null;
      });
    }

    try {
      // Gate on MappedDeptWithRole id — same source as web getSelectedDeptId().
      final mapped = await DepartmentService.instance.resolveForDashboard(
        selectedDeptId: RoleContext.instance.selectedDeptId,
      );
      if (!mounted || generation != _loadGeneration) return;
      if (RoleContext.instance.activePanel != SmartPanel.department) return;

      if (mapped == null) {
        final preferred = RoleContext.instance.selectedDeptId;
        AppLogger.d(
          'DepartmentDashboard',
          'No mapped dept for commonId '
          '(preferred=$preferred, env=${Env.baseUrl})',
        );
        setState(() {
          _data = const {};
          _loadedDeptId = null;
          _loading = false;
          _error = null;
          _selectDeptHint = preferred == null || preferred == '0'
              ? context.l(
                  'Select a department to view dashboard counts.',
                  'डैशबोर्ड गणना देखने के लिए विभाग चुनें।',
                )
              : context.l(
                  'Selected department is not in your mapped list. Switch department and try again.',
                  'चयनित विभाग आपकी मैप सूची में नहीं है। विभाग बदलकर पुनः प्रयास करें।',
                );
        });
        return;
      }

      if (RoleContext.instance.selectedDeptId != mapped.id ||
          RoleContext.instance.selectedDeptName != mapped.nameEn ||
          (RoleContext.instance.selectedDeptNameHi ?? '') != mapped.nameHi) {
        await RoleContext.instance.setDepartment(
          id: mapped.id,
          name: mapped.nameEn,
          nameHi: mapped.nameHi,
        );
      }
      if (!mounted || generation != _loadGeneration) return;

      final deptId = mapped.id;
      AppLogger.d(
        'DepartmentDashboard',
        'Fetching counts commonId=$deptId env=${Env.baseUrl}',
      );

      final raw = await DashboardService.instance.fetchDepartmentCounts(
        departmentId: deptId,
      );
      AppLogger.d(
        'DepartmentDashboard',
        'commonDashboardCount response keys=${raw.keys.toList()} '
        'TOTAL_SERVICE=${raw['TOTAL_SERVICE']} '
        'TOTAL_BENEFICIARY=${raw['TOTAL_BENEFICIARY']} '
        'UNIQUE_BENEFICIARY=${raw['UNIQUE_BENEFICIARY']}',
      );

      final data = DashboardService.unwrapDashboardData(raw);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _data = data;
        _loadedDeptId = deptId;
        _loading = false;
        _error = null;
        _selectDeptHint = null;
      });
    } catch (e) {
      AppLogger.e(
        'DepartmentDashboard',
        'commonDashboardCount failed '
        '(deptId=${RoleContext.instance.selectedDeptId}, env=${Env.baseUrl})',
        e,
      );
      if (!mounted || generation != _loadGeneration) return;
      final api = ApiErrorUtil.asApiException(e);
      setState(() {
        _data = const {};
        // Allow retry on same dept after failure (do not stick _loadedDeptId).
        _loadedDeptId = null;
        _selectDeptHint = null;
        _error = api.message.isNotEmpty
            ? api.message
            : context.l(
                'Unable to load dashboard counts. Please retry.',
                'डैशबोर्ड गणना लोड नहीं हो सकी। कृपया पुनः प्रयास करें।',
              );
        _loading = false;
      });
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
    final roleCtx = RoleContext.instance;
    final deptName = context.lb(
      roleCtx.selectedDeptName ?? '',
      roleCtx.selectedDeptNameHi ?? roleCtx.selectedDeptName ?? '',
    );

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
            if (_selectDeptHint != null) ...[
              DataScreenStates.error(
                context: context,
                message: _selectDeptHint!,
                onRetry: _load,
              ),
              const SizedBox(height: 16),
            ],
            // Show KPI cards only after a successful load (or with zeros from API).
            if (_error == null && _selectDeptHint == null) _kpiSection(),
          ],
        ],
      ),
    );
  }
}
