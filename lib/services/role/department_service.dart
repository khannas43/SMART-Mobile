import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import '../../core/app_logger.dart';
import '../../i18n/app_locale.dart';
import '../smart_api_client.dart';

class MappedDepartment {
  const MappedDepartment({
    required this.id,
    required this.nameEn,
    this.nameHi = '',
  });

  final String id;
  final String nameEn;
  final String nameHi;

  /// English name (backward-compatible). Prefer [localizedName] in UI.
  String get name => nameEn;

  String localizedName(BuildContext context) => context.lb(nameEn, nameHi);

  String localizedNameForLocale({required bool isHindi}) {
    final en = nameEn.trim();
    final hi = nameHi.trim();
    if (isHindi) return hi.isNotEmpty ? hi : en;
    return en.isNotEmpty ? en : hi;
  }

  factory MappedDepartment.fromRow(Map<String, dynamic> row) {
    final id = _pick(row, const ['id', 'ID', 'departmentId', 'DEPARTMENT_ID']);
    final nameEn = _pick(row, const [
      'departmentName',
      'DEPARTMENT_NAME',
      'departmentNameEn',
      'DEPARTMENT_NAME_EN',
      'nameEn',
      'NAME_EN',
      'name',
    ]);
    final nameHi = _pick(row, const [
      'departmentNameHi',
      'DEPARTMENT_NAME_HI',
      'nameHi',
      'NAME_HI',
    ]);
    return MappedDepartment(
      id: id,
      nameEn: nameEn.isNotEmpty ? nameEn : 'Department $id',
      nameHi: nameHi,
    );
  }

  factory MappedDepartment.fromApi(Map<String, dynamic> json) {
    return MappedDepartment.fromRow(json);
  }

  static String _pick(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      for (final entry in row.entries) {
        if (entry.key.toUpperCase() == key.toUpperCase()) {
          final text = entry.value?.toString().trim();
          if (text != null && text.isNotEmpty) return text;
        }
      }
    }
    return '';
  }
}

/// Fetches departments mapped to the logged-in SSO user.
class DepartmentService {
  DepartmentService._();

  static final DepartmentService instance = DepartmentService._();

  final SmartApiClient _client = SmartApiClient.instance;

  List<MappedDepartment>? _cache;

  List<MappedDepartment>? get cachedDepartments => _cache;

  void clearCache() => _cache = null;

  /// Resolves department id from mapped list (web `getSelectedDeptId` source).
  Future<MappedDepartment?> resolveDepartment({String? preferredDepartmentId}) async {
    final depts = await fetchMappedDepartments();
    if (depts.isEmpty) return null;

    if (preferredDepartmentId != null &&
        preferredDepartmentId.isNotEmpty &&
        preferredDepartmentId != '0') {
      for (final dept in depts) {
        if (dept.id == preferredDepartmentId) return dept;
      }
    }

    if (depts.length == 1) return depts.first;
    return null;
  }

  Future<MappedDepartment?> resolveForDashboard({String? selectedDeptId}) async {
    return resolveDepartment(preferredDepartmentId: selectedDeptId);
  }

  Future<bool> isMappedDepartmentId(String? departmentId) async {
    if (departmentId == null ||
        departmentId.isEmpty ||
        departmentId == '0') {
      return false;
    }
    final depts = await fetchMappedDepartments();
    return depts.any((d) => d.id == departmentId);
  }

  /// GET /api/department/mapped — ACTIVE depts for JWT user (EN + HI names).
  Future<List<MappedDepartment>> fetchMappedDepartments({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache != null) {
      return _cache!;
    }

    try {
      final response = await _client.get<dynamic>(
        '/api/department/mapped',
        options: Options(extra: {'roleHeader': 'DEPARTMENT'}),
      );

      final depts = _parseResponse(response.data);
      _cache = depts;
      AppLogger.d(
        'DepartmentService',
        'Loaded ${depts.length} mapped departments',
      );
      return depts;
    } catch (e) {
      AppLogger.d('DepartmentService', 'mapped departments failed: $e');
      rethrow;
    }
  }

  List<MappedDepartment> _parseResponse(dynamic data) {
    List<dynamic> rows = const [];

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final payload = map['data'] ?? map['Data'] ?? map['rows'];
      if (payload is List) {
        rows = payload;
      }
    } else if (data is List) {
      rows = data;
    }

    return rows
        .whereType<Map>()
        .map((row) => MappedDepartment.fromApi(Map<String, dynamic>.from(row)))
        .where((d) => d.id.isNotEmpty)
        .toList();
  }
}
