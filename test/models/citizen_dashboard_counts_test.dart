import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/models/citizen_dashboard_counts.dart';

void main() {
  test('CitizenDashboardCounts maps service block from API', () {
    final counts = CitizenDashboardCounts.fromApiMap({
      'service': {
        'ELIGIBLE_COUNT': 12,
        'AVAILED_COUNT': 5,
        'INPROCESS_COUNT': 2,
        'OPTOUT_COUNT': 1,
      },
    });

    expect(counts.eligibleCount, 12);
    expect(counts.availedCount, 5);
    expect(counts.inProcessCount, 2);
    expect(counts.optOutCount, 1);
    expect(counts.consentCount, 0);
  });

  test('CitizenDashboardCounts reads nested keys case-insensitively', () {
    final counts = CitizenDashboardCounts.fromApiMap({
      'SERVICE': {
        'eligible_count': '3',
        'availed_count': 7,
      },
      'consent': {
        'TOTAL_COUNT': 4,
      },
    });

    expect(counts.eligibleCount, 3);
    expect(counts.availedCount, 7);
    expect(counts.consentCount, 4);
  });
}
