import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/services/role/department_service.dart';

void main() {
  group('MappedDepartment.fromRow', () {
    test('parses English and Hindi department names', () {
      final dept = MappedDepartment.fromRow({
        'id': 42,
        'departmentName': 'Education',
        'departmentNameHi': 'शिक्षा',
        'status': 'ACTIVE',
      });
      expect(dept.id, '42');
      expect(dept.nameEn, 'Education');
      expect(dept.nameHi, 'शिक्षा');
      expect(dept.name, 'Education');
      expect(dept.localizedNameForLocale(isHindi: true), 'शिक्षा');
      expect(dept.localizedNameForLocale(isHindi: false), 'Education');
    });

    test('falls back to English when Hindi is blank', () {
      final dept = MappedDepartment.fromRow({
        'ID': '7',
        'departmentNameEn': 'Health',
      });
      expect(dept.id, '7');
      expect(dept.nameEn, 'Health');
      expect(dept.localizedNameForLocale(isHindi: true), 'Health');
    });

    test('parses API payload field names', () {
      final dept = MappedDepartment.fromApi({
        'id': 3,
        'departmentName': 'IT',
        'departmentNameHi': 'सूचना प्रौद्योगिकी',
      });
      expect(dept.id, '3');
      expect(dept.nameHi, 'सूचना प्रौद्योगिकी');
    });
  });
}
