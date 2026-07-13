import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/models/sso_role_mapping.dart';
import 'package:smart_rajasthan/models/user_role.dart';
import 'package:smart_rajasthan/services/role/role_context.dart';

import '../helpers/fake_secure_storage.dart';

void main() {
  setUp(installFakeSecureStorage);
  tearDown(() async {
    await RoleContext.instance.clear();
    tearDownFakeSecureStorage();
  });

  test('setMappings forces citizen panel for citizen-only mappings', () async {
    RoleContext.instance.setActivePanel(SmartPanel.department);
    await RoleContext.instance.setMappings(const [
      SsoRoleMapping(roleType: 'CITIZEN', mappingSerialNo: 1),
    ]);

    expect(RoleContext.instance.activePanel, SmartPanel.citizen);
    expect(RoleContext.instance.canSwitchPanels, isFalse);
  });

  test('switchPanel blocks cross-panel navigation when switching disabled', () async {
    await RoleContext.instance.setMappings(const [
      SsoRoleMapping(roleType: 'CITIZEN', mappingSerialNo: 1),
    ]);
    expect(RoleContext.instance.activePanel, SmartPanel.citizen);

    await RoleContext.instance.switchPanel(SmartPanel.department);

    expect(RoleContext.instance.activePanel, SmartPanel.citizen);
  });

  test('switchPanel allows citizen panel for department-only mappings', () async {
    await RoleContext.instance.setMappings(const [
      SsoRoleMapping(roleType: 'DEPARTMENT', mappingSerialNo: 2),
      SsoRoleMapping(roleType: 'CITIZEN'),
    ]);
    expect(RoleContext.instance.canSwitchPanels, isTrue);

    await RoleContext.instance.switchPanel(SmartPanel.citizen);

    expect(RoleContext.instance.activePanel, SmartPanel.citizen);
  });
}
