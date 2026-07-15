import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/services/role/department_service.dart';

void main() {
  group('MappedDepartment.fromRow', () {
    test('uses departmentName from DepartmentRegistration entity', () {
      final dept = MappedDepartment.fromRow({
        'id': 42,
        'departmentName': 'Education',
        'status': 'ACTIVE',
      });
      expect(dept.id, '42');
      expect(dept.name, 'Education');
    });

    test('falls back when only departmentNameEn is present', () {
      final dept = MappedDepartment.fromRow({
        'ID': '7',
        'departmentNameEn': 'Health',
      });
      expect(dept.id, '7');
      expect(dept.name, 'Health');
    });
  });
}
