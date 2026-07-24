import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/app_logger.dart';
import '../../models/report_models.dart';
import '../../models/sso_role_mapping.dart';
import '../../models/user_role.dart';
import '../auth_service.dart';
import 'department_service.dart';
import 'role_resolver.dart';

/// Holds active panel, role mappings, department selection, and report filters.
class RoleContext extends ChangeNotifier {
  RoleContext._({
    FlutterSecureStorage? storage,
  }) : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  @visibleForTesting
  factory RoleContext.forTest({FlutterSecureStorage? storage}) =>
      RoleContext._(storage: storage);

  static final RoleContext instance = RoleContext._();

  static const _deptIdKey = 'smart_selected_dept_id';
  static const _deptNameKey = 'smart_selected_dept_name';
  static const _deptNameHiKey = 'smart_selected_dept_name_hi';
  static const _panelKey = 'smart_active_panel';

  final FlutterSecureStorage _storage;

  List<SsoRoleMapping> _mappings = const [];
  SsoRoleMapping? _activeMapping;
  SmartPanel? _activePanel;
  String? _selectedDeptId;
  String? _selectedDeptName;
  String? _selectedDeptNameHi;
  ReportFilterState _reportFilter = ReportFilterState.defaultRange();

  List<SsoRoleMapping> get mappings => _mappings;

  SsoRoleMapping? get activeMapping => _activeMapping;

  SmartPanel? get activePanel => _activePanel;

  String? get selectedDeptId => _selectedDeptId;

  String? get selectedDeptName => _selectedDeptName;

  String? get selectedDeptNameHi => _selectedDeptNameHi;

  ReportFilterState get reportFilter => _reportFilter;

  String get currentRoleHeader =>
      _activePanel?.headerValue ?? SmartPanel.citizen.headerValue;

  String? get levelIdHeader {
    final id = _activeMapping?.levelId;
    if (id != null) return id.toString();
    if (_activePanel == SmartPanel.department) {
      return '3';
    }
    return null;
  }

  String? get districtIdsHeader => _activeMapping?.districtIds;

  String? get blockIdsHeader => _activeMapping?.blockIds;

  Set<SmartPanel> get availablePanels => RoleResolver.visiblePanels(
        _mappings,
        session: AuthService.instance.session,
      );

  List<SsoRoleMapping> mappingsForPanel(SmartPanel panel) {
    return _mappings.where((m) => m.panel == panel).toList();
  }

  bool get canSwitchPanels => RoleResolver.canSwitchPanels(
        _mappings,
        session: AuthService.instance.session,
      );

  Future<void> initialize() async {
    _selectedDeptId = await _storage.read(key: _deptIdKey);
    _selectedDeptName = await _storage.read(key: _deptNameKey);
    _selectedDeptNameHi = await _storage.read(key: _deptNameHiKey);
    final savedPanel = await _storage.read(key: _panelKey);
    if (savedPanel != null && savedPanel != 'admin') {
      _activePanel = SmartPanel.values.firstWhere(
        (p) => p.name == savedPanel,
        orElse: () => SmartPanel.citizen,
      );
    } else if (savedPanel == 'admin') {
      await _storage.delete(key: _panelKey);
    }
  }

  Future<void> setMappings(List<SsoRoleMapping> mappings) async {
    _mappings = mappings;
    if (!canSwitchPanels) {
      await switchPanel(
        RoleResolver.primaryPanel(
          mappings,
          session: AuthService.instance.session,
        ),
      );
    } else if (_activePanel == null || !availablePanels.contains(_activePanel)) {
      await switchPanel(RoleResolver.defaultPanel(mappings));
    } else {
      _syncActiveMapping();
    }
    notifyListeners();
  }

  void setActivePanel(SmartPanel panel) {
    _activePanel = panel;
    if (_mappings.isNotEmpty) {
      _syncActiveMapping();
    }
    notifyListeners();
  }

  Future<void> switchPanel(SmartPanel panel) async {
    if (!availablePanels.contains(panel)) return;

    if (!canSwitchPanels) {
      final primary = RoleResolver.primaryPanel(
        _mappings,
        session: AuthService.instance.session,
      );
      if (panel != primary) return;
    }

    _activePanel = panel;
    await _storage.write(key: _panelKey, value: panel.name);

    if (panel == SmartPanel.department) {
      final deptMappings = mappingsForPanel(SmartPanel.department);
      if (deptMappings.length == 1) {
        try {
          await _applyDepartmentMapping(deptMappings.first);
        } catch (e) {
          AppLogger.d(
            'RoleContext',
            'Department mapping apply skipped during panel switch: $e',
          );
          _activeMapping = deptMappings.first;
        }
      } else if (_selectedDeptId != null) {
        final match = deptMappings.where(
          (m) => m.departmentId?.toString() == _selectedDeptId,
        );
        if (match.isNotEmpty) {
          _activeMapping = match.first;
        }
      }
    } else {
      final panelMappings = mappingsForPanel(panel);
      _activeMapping = panelMappings.isNotEmpty
          ? panelMappings.first
          : _mappings.firstWhere(
              (m) => m.panel == SmartPanel.citizen,
              orElse: () => _mappings.first,
            );
      if (panel != SmartPanel.department) {
        _selectedDeptId = null;
        _selectedDeptName = null;
        _selectedDeptNameHi = null;
        await _storage.delete(key: _deptIdKey);
        await _storage.delete(key: _deptNameKey);
        await _storage.delete(key: _deptNameHiKey);
      }
    }

    if (panel != SmartPanel.department || _activeMapping != null) {
      _syncActiveMapping();
    }

    resetReportFilter();
    AppLogger.d('RoleContext', 'Switched panel to ${panel.name}');
    notifyListeners();
  }

  Future<void> setDepartment({
    required String id,
    required String name,
    String? nameHi,
    SsoRoleMapping? mapping,
  }) async {
    final changed = _selectedDeptId != id;
    _selectedDeptId = id;
    _selectedDeptName = name;
    _selectedDeptNameHi = nameHi ?? _selectedDeptNameHi;
    await _storage.write(key: _deptIdKey, value: id);
    await _storage.write(key: _deptNameKey, value: name);
    if (nameHi != null) {
      await _storage.write(key: _deptNameHiKey, value: nameHi);
    }

    if (mapping != null) {
      _activeMapping = mapping;
    } else {
      final match = mappingsForPanel(SmartPanel.department).where(
        (m) => m.departmentId?.toString() == id,
      );
      if (match.isNotEmpty) {
        _activeMapping = match.first;
      } else {
        _syncActiveMapping();
      }
    }
    if (changed) {
      resetReportFilter();
    }
    notifyListeners();
  }

  Future<void> _applyDepartmentMapping(SsoRoleMapping mapping) async {
    _activeMapping = mapping;
    final resolved = await DepartmentService.instance.resolveForDashboard(
      selectedDeptId: _selectedDeptId,
    );
    if (resolved != null) {
      await setDepartment(
        id: resolved.id,
        name: resolved.nameEn,
        nameHi: resolved.nameHi,
        mapping: mapping,
      );
      return;
    }

    final depts = await DepartmentService.instance.fetchMappedDepartments();
    if (depts.length == 1) {
      await setDepartment(
        id: depts.first.id,
        name: depts.first.nameEn,
        nameHi: depts.first.nameHi,
        mapping: mapping,
      );
    }
  }

  /// Ensures [selectedDeptId] uses MappedDeptWithRole id (same as web).
  /// Clears invalid stored ids that are not in the mapped list when a single
  /// mapped dept can replace them; otherwise leaves multi-dept for the picker.
  Future<void> syncDepartmentFromMappedList() async {
    try {
      final depts =
          await DepartmentService.instance.fetchMappedDepartments();
      if (depts.isEmpty) return;

      final current = _selectedDeptId;
      final stillValid = current != null &&
          current != '0' &&
          depts.any((d) => d.id == current);

      if (stillValid) {
        final match = depts.firstWhere((d) => d.id == current);
        final nameChanged = _selectedDeptName != match.nameEn ||
            (_selectedDeptNameHi ?? '') != match.nameHi;
        if (nameChanged) {
          await setDepartment(
            id: match.id,
            name: match.nameEn,
            nameHi: match.nameHi,
          );
        }
        return;
      }

      if (depts.length == 1) {
        await setDepartment(
          id: depts.first.id,
          name: depts.first.nameEn,
          nameHi: depts.first.nameHi,
        );
        return;
      }

      // Multiple mapped depts but stored id is missing/invalid — clear so
      // dashboard does not send a JWT-only or stale commonId.
      if (current != null && current.isNotEmpty && current != '0') {
        AppLogger.d(
          'RoleContext',
          'Clearing unmapped selectedDeptId=$current',
        );
        _selectedDeptId = null;
        _selectedDeptName = null;
        _selectedDeptNameHi = null;
        await _storage.delete(key: _deptIdKey);
        await _storage.delete(key: _deptNameKey);
        await _storage.delete(key: _deptNameHiKey);
        notifyListeners();
      }
    } catch (e) {
      AppLogger.d('RoleContext', 'Department sync skipped: $e');
    }
  }

  void _syncActiveMapping() {
    if (_activePanel == null) return;
    final panelMappings = mappingsForPanel(_activePanel!);
    if (panelMappings.isEmpty) {
      _activeMapping = _mappings.firstWhere(
        (m) => m.roleTypeUpper == 'CITIZEN',
        orElse: () => _mappings.isNotEmpty
            ? _mappings.first
            : const SsoRoleMapping(roleType: 'CITIZEN'),
      );
      return;
    }
    if (_activePanel == SmartPanel.department && _selectedDeptId != null) {
      final match = panelMappings.where(
        (m) => m.departmentId?.toString() == _selectedDeptId,
      );
      _activeMapping = match.isNotEmpty ? match.first : panelMappings.first;
    } else {
      _activeMapping = panelMappings.first;
    }
  }

  void updateReportFilter(ReportFilterState filter) {
    _reportFilter = filter;
    notifyListeners();
  }

  void resetReportFilter() {
    _reportFilter = ReportFilterState.defaultRange();
    notifyListeners();
  }

  Set<String> get allowedServiceIds {
    final raw = _activeMapping?.serviceIds;
    if (raw == null || raw.trim().isEmpty) return {};
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
  }

  Future<void> clear() async {
    _mappings = const [];
    _activeMapping = null;
    _activePanel = null;
    _selectedDeptId = null;
    _selectedDeptName = null;
    _selectedDeptNameHi = null;
    _reportFilter = ReportFilterState.defaultRange();
    DepartmentService.instance.clearCache();
    await _storage.delete(key: _deptIdKey);
    await _storage.delete(key: _deptNameKey);
    await _storage.delete(key: _deptNameHiKey);
    await _storage.delete(key: _panelKey);
    notifyListeners();
  }
}
