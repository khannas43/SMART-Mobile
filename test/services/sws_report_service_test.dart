import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/models/report_models.dart';
import 'package:smart_rajasthan/services/reports/sws_report_service.dart';

void main() {
  group('SwsReportService.selectedRuralParamForTest', () {
    test('matches web memberList: Rural → "0", Urban → "1"', () {
      final now = DateTime.now();
      final rural = ReportFilterState(
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now,
        serviceId: '1000',
        serviceName: 'All',
        districtId: '1',
        districtName: 'Jaipur',
        selectedRural: 'Rural',
        selectedRuralId: 1, // store convention; must NOT drive API param
        blockId: '10',
        blockName: 'Block A',
      );
      final urban = ReportFilterState(
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now,
        serviceId: '1000',
        serviceName: 'All',
        districtId: '1',
        districtName: 'Jaipur',
        selectedRural: 'Urban',
        selectedRuralId: 0,
      );

      // Web: selectedRural === "Rural" ? "0" : "1"
      expect(SwsReportService.selectedRuralParamForTest(rural), '0');
      expect(SwsReportService.selectedRuralParamForTest(urban), '1');
    });

    test('IS_RURAL flag 1 → rural "0", flag 0 → urban "1"', () {
      final now = DateTime.now();
      final ruralFlag = ReportFilterState(
        startDate: now,
        endDate: now,
        selectedRural: '1',
      );
      final urbanFlag = ReportFilterState(
        startDate: now,
        endDate: now,
        selectedRural: '0',
      );
      expect(SwsReportService.selectedRuralParamForTest(ruralFlag), '0');
      expect(SwsReportService.selectedRuralParamForTest(urbanFlag), '1');
    });
  });
}
