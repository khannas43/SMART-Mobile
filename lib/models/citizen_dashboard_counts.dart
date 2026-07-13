/// Parsed response from `POST /smart/api/dashboard/citizenDashboardCount` (activity 2.10).
class CitizenDashboardCounts {
  const CitizenDashboardCounts({
    required this.eligibleCount,
    required this.availedCount,
    required this.inProcessCount,
    required this.optOutCount,
    required this.consentCount,
    required this.approvedConsentCount,
    required this.pendingConsentCount,
  });

  final int eligibleCount;
  final int availedCount;
  final int inProcessCount;
  final int optOutCount;
  final int consentCount;
  final int approvedConsentCount;
  final int pendingConsentCount;

  static const zero = CitizenDashboardCounts(
    eligibleCount: 0,
    availedCount: 0,
    inProcessCount: 0,
    optOutCount: 0,
    consentCount: 0,
    approvedConsentCount: 0,
    pendingConsentCount: 0,
  );

  factory CitizenDashboardCounts.fromApiMap(Map<String, dynamic> raw) {
    final service = _section(raw, 'service');
    final consent = _section(raw, 'consent');

    return CitizenDashboardCounts(
      eligibleCount: _int(service, const ['ELIGIBLE_COUNT', 'eligible_count']),
      availedCount: _int(service, const ['AVAILED_COUNT', 'availed_count']),
      inProcessCount: _int(service, const ['INPROCESS_COUNT', 'inprocess_count']),
      optOutCount: _int(service, const ['OPTOUT_COUNT', 'optout_count']),
      consentCount: _int(consent, const ['TOTAL_COUNT']),
      approvedConsentCount: _int(consent, const ['APPROVED_COUNT']),
      pendingConsentCount: _int(consent, const ['PENDING_COUNT']),
    );
  }

  Map<String, dynamic> toApiMap() => {
        'service': {
          'ELIGIBLE_COUNT': eligibleCount,
          'AVAILED_COUNT': availedCount,
          'INPROCESS_COUNT': inProcessCount,
          'OPTOUT_COUNT': optOutCount,
        },
        'consent': {
          'TOTAL_COUNT': consentCount,
          'APPROVED_COUNT': approvedConsentCount,
          'PENDING_COUNT': pendingConsentCount,
        },
      };

  static Map<String, dynamic> _section(Map<String, dynamic> raw, String key) {
    for (final entry in raw.entries) {
      if (entry.key.toUpperCase() == key.toUpperCase() && entry.value is Map) {
        return Map<String, dynamic>.from(entry.value as Map);
      }
    }
    return const {};
  }

  static int _int(Map<String, dynamic> section, List<String> keys) {
    for (final key in keys) {
      for (final entry in section.entries) {
        if (entry.key.toUpperCase() == key.toUpperCase()) {
          final value = entry.value;
          if (value is int) return value;
          if (value is num) return value.toInt();
          if (value is String) return int.tryParse(value) ?? 0;
        }
      }
    }
    return 0;
  }
}
