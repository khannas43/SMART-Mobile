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
    final rowId = eligibleRow['id']?.toString() ?? '';
    final serviceId = eligibleRow['serviceId']?.toString() ?? '';
    final serviceName = _serviceName(eligibleRow);
    final deptId = _pickInt(eligibleRow, const [
      'departmentId',
      'DEPARTMENT_ID',
      'consentDepartmentId',
    ]);
    final deptName = _pickString(eligibleRow, const [
      'departmentName',
      'DEPARTMENT_NAME',
      'departmentNameEn',
      'nameEn',
    ]);

    final consentPayload = {
      'serviceId': serviceId.isNotEmpty ? int.tryParse(serviceId) ?? serviceId : 0,
      'consentSubject': 'Citizen want to avail this $serviceName',
      'consentDetail': jsonEncode(const {'consent': 'Citizen Accepted'}),
      'consentRemark': 'Citizen want to avail this $serviceName',
      'consentDepartmentId': deptId,
      'consentDepartmentName': deptName,
      'consentApiId': 0,
      'consentLanguage': 'English',
      'consentType': 'AVAIL_SERVICE',
      'consentFor': 'DEPARTMENT',
      'consenterJaMemberId': smUserId,
      'consenterMemberName': userName,
      'citizenEligibleId': rowId,
      'serviceCode': serviceId,
      'serviceName': serviceName,
      'status': 'PENDING',
      if (otpTxnId != null) 'consentJaOtpTxnId': otpTxnId,
      if (otpValidationResponse != null)
        'consentJaOtpTxnResponse': jsonEncode(otpValidationResponse),
    };

    await Future.wait([
      _nextQuery.update(
        model: 'EligibleServices',
        idField: 'id',
        idValue: rowId,
        data: const {'status': 'SUCCESS'},
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
