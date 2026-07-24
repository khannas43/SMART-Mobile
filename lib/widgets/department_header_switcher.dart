import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../i18n/app_locale.dart';
import '../models/user_role.dart';
import '../services/api_error_util.dart';
import '../services/role/department_service.dart';
import '../services/role/role_context.dart';

/// Department name control for Department panel header.
///
/// - Hidden when user has no Department role / not on department panel.
/// - Single mapped dept → read-only text.
/// - Multiple mapped depts → dropdown to switch (refreshes KPIs/reports).
class DepartmentHeaderSwitcher extends StatefulWidget {
  const DepartmentHeaderSwitcher({super.key});

  @override
  State<DepartmentHeaderSwitcher> createState() =>
      _DepartmentHeaderSwitcherState();
}

class _DepartmentHeaderSwitcherState extends State<DepartmentHeaderSwitcher> {
  List<MappedDepartment> _depts = const [];
  var _loading = true;
  String? _error;

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
    setState(() {});
  }

  Future<void> _load() async {
    final roleCtx = RoleContext.instance;
    if (roleCtx.activePanel != SmartPanel.department ||
        !roleCtx.availablePanels.contains(SmartPanel.department)) {
      if (mounted) {
        setState(() {
          _depts = const [];
          _loading = false;
          _error = null;
        });
      }
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final depts = await DepartmentService.instance.fetchMappedDepartments();
      if (!mounted) return;
      setState(() {
        _depts = depts;
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

  Future<void> _onDeptChanged(String? id) async {
    if (id == null || id.isEmpty) return;
    MappedDepartment? match;
    for (final d in _depts) {
      if (d.id == id) {
        match = d;
        break;
      }
    }
    if (match == null) return;
    if (match.id == RoleContext.instance.selectedDeptId) return;

    await RoleContext.instance.setDepartment(
      id: match.id,
      name: match.nameEn,
      nameHi: match.nameHi,
    );
  }

  String _displayName(MappedDepartment dept) => dept.localizedName(context);

  String? _selectedDisplayName() {
    final roleCtx = RoleContext.instance;
    final selectedId = roleCtx.selectedDeptId;
    for (final d in _depts) {
      if (d.id == selectedId) return _displayName(d);
    }
    return context.lb(
      roleCtx.selectedDeptName ?? '',
      roleCtx.selectedDeptNameHi ?? roleCtx.selectedDeptName ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    final roleCtx = RoleContext.instance;

    // Citizen-only / no department role → never show dept switcher.
    if (roleCtx.activePanel != SmartPanel.department ||
        !roleCtx.availablePanels.contains(SmartPanel.department)) {
      return const SizedBox.shrink();
    }

    if (_loading && _depts.isEmpty) {
      return const SizedBox(
        height: 14,
        width: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_error != null && _depts.isEmpty) {
      return GestureDetector(
        onTap: _load,
        child: Text(
          context.l('Retry department', 'विभाग पुनः लोड करें'),
          style: const TextStyle(fontSize: 11, color: kMuted),
        ),
      );
    }

    final selectedId = roleCtx.selectedDeptId;
    final selectedName = _selectedDisplayName()?.trim();

    if (_depts.isEmpty) {
      if (selectedName != null && selectedName.isNotEmpty) {
        return Text(
          selectedName,
          style: const TextStyle(fontSize: 11, color: kMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      }
      return const SizedBox.shrink();
    }

    if (_depts.length == 1) {
      final name = _displayName(_depts.first);
      return Text(
        name,
        style: const TextStyle(fontSize: 11, color: kMuted),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final valueInList = _depts.any((d) => d.id == selectedId)
        ? selectedId
        : _depts.first.id;

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isDense: true,
        isExpanded: true,
        value: valueInList,
        icon: const Icon(Icons.arrow_drop_down, size: 18, color: kMuted),
        style: const TextStyle(fontSize: 11, color: kText),
        items: [
          for (final d in _depts)
            DropdownMenuItem<String>(
              value: d.id,
              child: Text(
                _displayName(d),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: _onDeptChanged,
      ),
    );
  }
}
