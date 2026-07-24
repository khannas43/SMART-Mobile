import '../services/auth_service.dart';
import '../services/next_query_client.dart';

/// Result from consent list-count API.
class ConsentListResult {
  const ConsentListResult({required this.rows, required this.total});

  final List<Map<String, dynamic>> rows;
  final int total;
}

/// Citizen consent list (CitizenServiceConsent nextquery) — UAT `/citizen/viewConsent`.
class ConsentService {
  ConsentService._();

  static final ConsentService instance = ConsentService._();

  final NextQueryClient _nextQuery = NextQueryClient.instance;

  static const pageSize = 10;

  static const _fields =
      'id,consentSubject,consentDetail,consentRemark,consentDepartmentId,'
      'consentDepartmentName,consentApiId,consentLanguage,consentType,'
      'consenterJaFamilyId,consenterJaMemberId,consenterSmCitizenId,'
      'consenterMemberName,consenterMobile,consentStackholderRegistrationId,'
      'consentStackholderRegistrationResponse,consentJaOtpTxnId,'
      'consentJaOtpTxnResponse,serviceId,serviceCode,serviceName,status,'
      'statusActivity,consentVerifiedDate,createDate,updateDate';

  Future<ConsentListResult> fetchConsents({
    int page = 1,
    int size = pageSize,
  }) async {
    final smUserId = AuthService.instance.session?.smUserId;
    if (smUserId == null || smUserId.isEmpty) {
      return const ConsentListResult(rows: [], total: 0);
    }

    final result = await _nextQuery.listCount(
      model: 'CitizenServiceConsent',
      fields: _fields,
      // Match web ConsentList: consents are stored with consenterJaMemberId.
      filters: {
        'and': [
          {'field': 'consenterJaMemberId', 'op': '=', 'value': smUserId},
        ],
      },
      page: page,
      size: size,
      roleHeader: 'CITIZEN',
    );
    return ConsentListResult(rows: result.rows, total: result.total);
  }
}
