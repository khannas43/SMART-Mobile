import 'dart:convert';

/// Builds unsigned JWT strings for unit tests.
String buildTestJwt(Map<String, dynamic> payload) {
  final header = base64Url.encode(utf8.encode('{"alg":"none","typ":"JWT"}'));
  final body = base64Url.encode(utf8.encode(jsonEncode(payload)));
  return '$header.$body.test-signature';
}

/// JWT with far-future expiry for auth service tests.
String validCitizenJwt({
  String ssoId = 'TEST.SSO',
  String smUserId = '123456789',
  String name = 'Test Citizen',
  String? sub,
}) {
  final exp = DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch ~/ 1000;
  return buildTestJwt({
    'ssoId': ssoId,
    'smUserId': smUserId,
    'Name': name,
    'currentSrole': 'citizen',
    'panelTypes': ['CITIZEN'],
    'SmartRole': 'CITIZEN',
    'exp': exp,
    if (sub != null) 'sub': sub,
  });
}

String validAdminJwt() {
  final exp = DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch ~/ 1000;
  return buildTestJwt({
    'ssoId': 'ADMIN.SSO',
    'Name': 'Test Admin',
    'currentSrole': 'admin',
    'panelTypes': ['ADMIN', 'CITIZEN'],
    'SmartRole': ['ADMIN', 'CITIZEN'],
    'exp': exp,
  });
}

String validDepartmentJwt() {
  final exp = DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch ~/ 1000;
  return buildTestJwt({
    'ssoId': 'DEPT.SSO',
    'Name': 'Test Dept User',
    'currentSrole': 'department',
    'panelTypes': ['DEPARTMENT'],
    'SmartRole': 'DEPARTMENT',
    'departmentId': '101',
    'exp': exp,
  });
}

String expiredJwt() {
  final exp = DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
  return buildTestJwt({
    'ssoId': 'EXPIRED',
    'currentSrole': 'citizen',
    'exp': exp,
  });
}
