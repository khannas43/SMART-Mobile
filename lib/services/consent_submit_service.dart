import 'dart:convert';

import 'auth_service.dart';
import 'next_query_client.dart';

/// Post-OTP avail service + create consent (web `SchemeVerificationModal`).
class ConsentSubmitService {
  ConsentSubmitService._();

  static final ConsentSubmitService instance = ConsentSubmitService._();

  final NextQueryClient _nextQuery = NextQueryClient.instance;

  Future<void> availServiceAndCreateConsent({
    required Map<String, dynamic> eligibleRow,
    required String? otpTxnId,
    required Map<String, dynamic>? otpValidationResponse,
  }) async {
    final session = AuthService.instance.session;
    final smUserId = session?.smUserId ?? '';
    final userName = session?.userName ?? 'Citizen';
    final ssoId = session?.ssoId ?? '';
    final rowId = eligibleRow['id']?.toString() ?? '';
    final serviceIdRaw = eligibleRow['serviceId'];
    final serviceId = serviceIdRaw is int
        ? serviceIdRaw
        : int.tryParse(serviceIdRaw?.toString() ?? '') ?? serviceIdRaw ?? 0;
    final serviceName = _serviceName(eligibleRow);
    final memberId = _pickString(eligibleRow, const [
      'memberId',
      'MEMBER_ID',
      'refMemberId',
    ]);
    final citizenName = _pickString(eligibleRow, const [
      'nameEn',
      'NAME_EN',
      'memberName',
      'nameHi',
    ]);
    final deptId = _pickInt(eligibleRow, const [
      'departmentId',
      'DEPARTMENT_ID',
      'consentDepartmentId',
    ]);
    final deptName = _pickString(eligibleRow, const [
      'departmentName',
      'DEPARTMENT_NAME',
      'departmentNameEn',
    ]);

    // Match web `SchemeVerificationModal.updateAppliedServiceStatus` payloads.
    final consentPayload = {
      'serviceId': serviceId,
      'consentSubject':
          'Consent given successfully, to avail the service $serviceName',
      'consentDetail': jsonEncode({
        'consent':
            'You have given consent successfully to avail the service $serviceName',
        'serviceName': serviceName,
        'serviceId': serviceId,
      }),
      'consentRemark':
          'Citizen has given consent successfully to avail $serviceName',
      'consentDepartmentId': deptId,
      'consentDepartmentName': deptName,
      'consentApiId': 0,
      'consentLanguage': 'English',
      'consentType': 'AVAIL_SERVICE',
      'consentFor': 'SMS_JANAADHAAR_ADDITION_AVAILED_WITH_CONSENT',
      'consenterJaMemberId': smUserId,
      'consenterMemberName': userName,
      'citizenEligibleId': rowId,
      'serviceCode': serviceId,
      'serviceName': serviceName,
      'status': 'SUCCESS',
      if (otpTxnId != null) 'consentJaOtpTxnId': otpTxnId,
      if (otpValidationResponse != null)
        'consentJaOtpTxnResponse': jsonEncode(otpValidationResponse),
      'citizenJaMemberId': memberId,
      'citizenMemberName': citizenName.isNotEmpty ? citizenName : userName,
      'consenterSsoId': ssoId,
    };

    await Future.wait([
      _nextQuery.update(
        model: 'EligibleServices',
        idField: 'id',
        idValue: rowId,
        data: const {'status': 'INSERT'},
        roleHeader: 'CITIZEN',
      ),
      _nextQuery.create(
        model: 'CitizenServiceConsent',
        data: consentPayload,
        roleHeader: 'CITIZEN',
      ),
    ]);
  }

  String _serviceName(Map<String, dynamic> row) {
    return _pickString(row, const [
      'serviceName',
      'SERVICE_NAME',
      'nameEn',
      'NAME_EN',
      'nameHi',
    ]).ifEmpty('Service');
  }

  static int _pickInt(Map<String, dynamic> row, List<String> keys) {
    final text = _pickString(row, keys);
    return int.tryParse(text) ?? 0;
  }

  static String _pickString(Map<String, dynamic> row, List<String> keys) {
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

extension _StringEmpty on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
