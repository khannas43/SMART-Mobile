import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/i18n/app_locale.dart';
import 'package:smart_rajasthan/models/sso_role_mapping.dart';
import 'package:smart_rajasthan/models/user_role.dart';
import 'package:smart_rajasthan/services/auth_service.dart';
import 'package:smart_rajasthan/services/role/role_context.dart';
import 'package:smart_rajasthan/widgets/role_switcher.dart';

import '../helpers/fake_secure_storage.dart';
import '../helpers/jwt_test_utils.dart';

Widget _wrap(Widget child) {
  return AppLocaleScope(
    notifier: AppLocaleController.instance,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  setUp(() {
    installFakeSecureStorage();
  });

  tearDown(() async {
    await RoleContext.instance.clear();
    AuthService.instance.acknowledgeSessionEnded();
    await AuthService.instance.clearToken();
    tearDownFakeSecureStorage();
  });

  testWidgets('RoleSwitcher hidden for citizen-only JWT', (tester) async {
    await AuthService.instance.saveToken(validCitizenJwt());
    RoleContext.instance.setActivePanel(SmartPanel.citizen);
    await RoleContext.instance.setMappings(const [
      SsoRoleMapping(roleType: 'CITIZEN', mappingSerialNo: 1),
    ]);

    await tester.pumpWidget(_wrap(const RoleSwitcher()));
    await tester.pump();

    expect(find.byType(PopupMenuButton<SmartPanel>), findsNothing);
    expect(find.text('Citizen'), findsNothing);
  });

  testWidgets('RoleSwitcher visible for department-only JWT', (tester) async {
    await AuthService.instance.saveToken(validDepartmentJwt());
    RoleContext.instance.setActivePanel(SmartPanel.department);
    await RoleContext.instance.setMappings(const [
      SsoRoleMapping(roleType: 'DEPARTMENT', mappingSerialNo: 2),
      SsoRoleMapping(roleType: 'CITIZEN'),
    ]);

    await tester.pumpWidget(_wrap(const RoleSwitcher()));
    await tester.pump();

    expect(find.byType(PopupMenuButton<SmartPanel>), findsOneWidget);
    expect(find.text('Department'), findsOneWidget);
  });

  testWidgets('RoleSwitcher visible for dual-role JWT', (tester) async {
    final exp =
        DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch ~/
            1000;
    await AuthService.instance.saveToken(
      buildTestJwt({
        'ssoId': 'DUAL.SSO',
        'Name': 'Dual User',
        'currentSrole': 'citizen',
        'panelTypes': ['CITIZEN', 'DEPARTMENT'],
        'SmartRole': ['CITIZEN', 'DEPARTMENT'],
        'exp': exp,
      }),
    );
    RoleContext.instance.setActivePanel(SmartPanel.citizen);
    await RoleContext.instance.setMappings(const [
      SsoRoleMapping(roleType: 'CITIZEN', mappingSerialNo: 1),
      SsoRoleMapping(roleType: 'DEPARTMENT', mappingSerialNo: 2),
    ]);

    await tester.pumpWidget(_wrap(const RoleSwitcher()));
    await tester.pump();

    expect(find.byType(PopupMenuButton<SmartPanel>), findsOneWidget);
    expect(find.text('Citizen'), findsOneWidget);
  });
}
