import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../i18n/app_locale.dart';
import '../../services/api_error_util.dart';
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

  @override
  void initState() {
    super.initState();
    RoleContext.instance.addListener(_onRoleChanged);
    _load();
  }

  @override
  void dispose() {
    RoleContext.instance.removeListener(_onRoleChanged);
    super.dispose();
  }

  void _onRoleChanged() {
    if (!mounted) return;
    _load();
  }

  Future<void> _load() async {
    await RoleContext.instance.syncDepartmentFromMappedList();
    final deptId = RoleContext.instance.selectedDeptId;
    if (deptId == null || deptId == '0') {
      setState(() {
        _loading = false;
        _error = null;
        _data = const {};
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = DashboardService.unwrapDashboardData(
        await DashboardService.instance.fetchDepartmentCounts(
          departmentId: deptId,
        ),
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiErrorUtil.friendlyMessage(e);
        _loading = false;
      });
    }
  }

  String _val(String key) => DashboardService.stringValue(_data, key);

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
          else if (RoleContext.instance.selectedDeptId == null)
            DataScreenStates.empty(
              message: context.l(
                'Select a department to view dashboard counts.',
                'डैशबोर्ड गिनती देखने के लिए विभाग चुनें।',
              ),
            )
          else if (_error != null)
            DataScreenStates.error(context: context, message: _error!, onRetry: _load)
          else
            StatSection(
              titleEn: 'Overview',
              titleHi: 'अवलोकन',
              cards: [
                StatCardData(
                  labelEn: 'Total Services',
                  labelHi: 'कुल सेवाएं',
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
            ),
        ],
      ),
    );
  }
}
