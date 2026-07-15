import '../next_query_client.dart';

class MappedDepartment {
  const MappedDepartment({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory MappedDepartment.fromRow(Map<String, dynamic> row) {
    final id = _pick(row, const ['id', 'ID', 'departmentId', 'DEPARTMENT_ID']);
    final name = _pick(row, const [
      'departmentNameEn',
      'DEPARTMENT_NAME_EN',
      'nameEn',
      'NAME_EN',
      'departmentName',
    ]);
    return MappedDepartment(
      id: id,
      name: name.isNotEmpty ? name : 'Department $id',
    );
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

  /// Resolves department id from MappedDeptWithRole (web `getSelectedDeptId` source).
  /// Matches web LoginProfile: preferred match, else sole dept, else null (needs picker).
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

  /// Picks the mapped department row for dashboard `commonId` (same rules as web).
  Future<MappedDepartment?> resolveForDashboard({String? selectedDeptId}) async {
    return resolveDepartment(preferredDepartmentId: selectedDeptId);
  }

  Future<List<MappedDepartment>> fetchMappedDepartments() async {
    final result = await NextQueryClient.instance.list(
      model: 'DepartmentRegistration',
      fields: 'id,departmentNameEn,departmentNameHi,departmentCode',
      filters: const {
        'executeActionName': 'MappedDeptWithRole',
      },
      size: 100,
      roleHeader: 'DEPARTMENT',
    );

    return result.rows
        .map(MappedDepartment.fromRow)
        .where((d) => d.id.isNotEmpty)
        .toList();
  }
}
