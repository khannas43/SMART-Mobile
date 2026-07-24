import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/models/report_models.dart';

void main() {
  group('ReportFilterState.drillLevel', () {
    final base = ReportFilterState.defaultRange().copyWith(
      serviceId: '42',
      serviceName: 'Test Service',
    );

    test('starts at all services when no service selected', () {
      expect(
        ReportFilterState.defaultRange().drillLevel,
        ReportDrillLevel.allServices,
      );
    });

    test('district level after service selected', () {
      expect(base.drillLevel, ReportDrillLevel.districts);
    });

    test('rural/urban after district selected', () {
      final filters = base.copyWith(
        districtId: '1',
      );
      expect(filters.drillLevel, ReportDrillLevel.ruralUrban);
    });

    test('hasDistrict requires non-empty districtId only', () {
      expect(
        base.copyWith(districtId: '1', districtName: '').hasDistrict,
        isTrue,
      );
      expect(
        base.copyWith(districtId: '', districtName: 'Jaipur').hasDistrict,
        isFalse,
      );
    });

    test('blocks after rural selected', () {
      final filters = base.copyWith(
        districtId: '1',
        districtName: 'Jaipur',
        selectedRural: 'Rural',
        selectedRuralId: 1,
      );
      expect(filters.drillLevel, ReportDrillLevel.blocks);
    });

    test('urban stays at ruralUrban (no beneficiary drill)', () {
      final filters = base.copyWith(
        districtId: '1',
        districtName: 'Jaipur',
        selectedRural: 'Urban',
        selectedRuralId: 0,
      );
      expect(filters.drillLevel, ReportDrillLevel.ruralUrban);
    });

    test('block id does not open beneficiaries — stays on blocks', () {
      final filters = base.copyWith(
        districtId: '1',
        districtName: 'Jaipur',
        selectedRural: 'Rural',
        selectedRuralId: 1,
        blockId: '99',
        blockName: 'Block A',
      );
      expect(filters.drillLevel, ReportDrillLevel.blocks);
    });
  });
}
