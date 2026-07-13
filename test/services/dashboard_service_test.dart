import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/services/dashboard/dashboard_service.dart';

void main() {
  group('DashboardService.stringValue', () {
    test('finds value with exact key', () {
      final data = {'TOTAL_SERVICE': 42};
      expect(DashboardService.stringValue(data, 'TOTAL_SERVICE'), '42');
    });

    test('matches keys case-insensitively', () {
      final data = {
        'TOTAL_BENEFICIARY': '100',
        'unique_beneficiary': 7,
      };
      expect(DashboardService.stringValue(data, 'total_beneficiary'), '100');
      expect(DashboardService.stringValue(data, 'UNIQUE_BENEFICIARY'), '7');
    });

    test('returns 0 for missing or null values', () {
      expect(DashboardService.stringValue({}, 'TOTAL_SERVICE'), '0');
      expect(
        DashboardService.stringValue({'TOTAL_SERVICE': null}, 'TOTAL_SERVICE'),
        '0',
      );
    });
  });
}
