import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/models/auth_session.dart';
import 'package:smart_rajasthan/models/user_role.dart';
import 'package:smart_rajasthan/services/role/role_mapping_service.dart';

import '../helpers/jwt_test_utils.dart';

void main() {
  test('mappingsFromJwt always includes CITIZEN', () {
    final session = AuthSession.fromToken(validDepartmentJwt());
    expect(session, isNotNull);

    final mappings = RoleMappingService.instance.mappingsFromJwt(session!);
    expect(
      mappings.any((m) => m.panel == SmartPanel.citizen),
      isTrue,
    );
    expect(
      mappings.any((m) => m.panel == SmartPanel.department),
      isTrue,
    );
  });

  test('mappingsFromJwt excludes admin roles from mobile', () {
    final session = AuthSession.fromToken(validAdminJwt());
    expect(session, isNotNull);

    final mappings = RoleMappingService.instance.mappingsFromJwt(session!);
    expect(mappings.any((m) => m.panel == SmartPanel.department), isFalse);
    expect(mappings.any((m) => m.panel == SmartPanel.citizen), isTrue);
    expect(
      mappings.every((m) => m.roleTypeUpper != 'ADMIN' && m.roleTypeUpper != 'SUPER_ADMIN'),
      isTrue,
    );
  });
}
