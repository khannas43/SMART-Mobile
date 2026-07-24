import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../i18n/app_locale.dart';
import '../models/user_role.dart';
import '../screens/shared/dept_picker_dialog.dart';
import '../services/api_error_presenter.dart';
import '../services/api_error_util.dart';
import '../services/api_exception.dart';
import '../services/role/department_service.dart';
import '../services/role/role_context.dart';

/// Header panel switcher (mirrors web LoginProfile "Switch to").
class RoleSwitcher extends StatefulWidget {
  const RoleSwitcher({super.key, this.onPanelChanged});

  final VoidCallback? onPanelChanged;

  @override
  State<RoleSwitcher> createState() => _RoleSwitcherState();
}

class _RoleSwitcherState extends State<RoleSwitcher> {
  var _switching = false;

  Future<void> _selectPanel(BuildContext context, SmartPanel panel) async {
    if (_switching) return;
    final roleCtx = RoleContext.instance;
    if (roleCtx.activePanel == panel) return;
    setState(() => _switching = true);
    try {
      if (panel == SmartPanel.department) {
        final depts = await DepartmentService.instance.fetchMappedDepartments();
        if (!context.mounted) return;
        if (depts.isEmpty) {
          ApiErrorPresenter.show(
            ApiException(
              message: context.l(
                'No department mapped to your SSO account.',
                'आपके SSO खाते से कोई विभाग मैप नहीं है।',
              ),
            ),
          );
          return;
        }
        // Match web: picker when multiple MappedDeptWithRole rows.
        if (depts.length > 1) {
          final currentId = roleCtx.selectedDeptId;
          final stillValid = currentId != null &&
              currentId != '0' &&
              depts.any((d) => d.id == currentId);
          if (!stillValid) {
            final picked = await DeptPickerDialog.show(context, depts);
            if (picked == null) return;
            await roleCtx.switchPanel(SmartPanel.department);
            await roleCtx.setDepartment(
              id: picked.id,
              name: picked.nameEn,
              nameHi: picked.nameHi,
            );
          } else {
            await roleCtx.switchPanel(SmartPanel.department);
            await roleCtx.syncDepartmentFromMappedList();
          }
        } else {
          await roleCtx.switchPanel(panel);
          await roleCtx.setDepartment(
            id: depts.first.id,
            name: depts.first.nameEn,
            nameHi: depts.first.nameHi,
          );
        }
      } else {
        await roleCtx.switchPanel(panel);
      }
      widget.onPanelChanged?.call();
    } catch (e) {
      if (!context.mounted) return;
      ApiErrorPresenter.show(ApiErrorUtil.asApiException(e));
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    return ListenableBuilder(
      listenable: RoleContext.instance,
      builder: (context, _) {
        if (!RoleContext.instance.canSwitchPanels) {
          return const SizedBox.shrink();
        }

        final roleCtx = RoleContext.instance;
        final panels = roleCtx.availablePanels.toList()
          ..sort((a, b) => a.index.compareTo(b.index));

        final active = roleCtx.activePanel ?? SmartPanel.citizen;

        return PopupMenuButton<SmartPanel>(
          tooltip: context.l('Switch panel', 'पैनल बदलें'),
          enabled: !_switching,
          onSelected: (panel) => _selectPanel(context, panel),
          itemBuilder: (context) => [
            for (final panel in panels)
              PopupMenuItem(
                value: panel,
                child: Row(
                  children: [
                    Icon(_panelIcon(panel), size: 18, color: _panelColor(panel)),
                    const SizedBox(width: 10),
                    Text(_panelLabel(context, panel)),
                  ],
                ),
              ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(20),
                color: kBg,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_switching)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(Icons.layers_outlined, size: 16, color: _panelColor(active)),
                  const SizedBox(width: 6),
                  Text(
                    _panelShortLabel(context, active),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: kText,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: kMuted),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static IconData _panelIcon(SmartPanel panel) => switch (panel) {
        SmartPanel.citizen => Icons.person_outline_rounded,
        SmartPanel.department => Icons.business_outlined,
      };

  static Color _panelColor(SmartPanel panel) => switch (panel) {
        SmartPanel.citizen => kCitizenOrange,
        SmartPanel.department => kDeptNavyMid,
      };

  static String _panelLabel(BuildContext context, SmartPanel panel) =>
      switch (panel) {
        SmartPanel.citizen =>
          context.l('Citizen Panel', 'नागरिक पैनल'),
        SmartPanel.department =>
          context.l('Department Panel', 'विभाग पैनल'),
      };

  static String _panelShortLabel(BuildContext context, SmartPanel panel) =>
      switch (panel) {
        SmartPanel.citizen => context.l('Citizen', 'नागरिक'),
        SmartPanel.department => context.l('Department', 'विभाग'),
      };
}
