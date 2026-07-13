import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/models/sso_role_mapping.dart';
import 'package:smart_rajasthan/models/user_role.dart';
import 'package:smart_rajasthan/services/role/role_resolver.dart';

void main() {
  test('defaultPanel is DEPARTMENT when dept mapping exists', () {
    expect(
      RoleResolver.defaultPanel(const [
        SsoRoleMapping(roleType: 'DEPARTMENT'),
        SsoRoleMapping(roleType: 'CITIZEN'),
      ]),
      SmartPanel.department,
    );
  });

  test('defaultPanel is CITIZEN when only citizen mapping exists', () {
    expect(
      RoleResolver.defaultPanel(const [
        SsoRoleMapping(roleType: 'CITIZEN'),
      ]),
      SmartPanel.citizen,
    );
  });

  test('visiblePanels hides department for citizen-only JWT', () {
    final panels = RoleResolver.visiblePanels(
      const [
        SsoRoleMapping(roleType: 'DEPARTMENT'),
        SsoRoleMapping(roleType: 'CITIZEN'),
      ],
      jwtRoles: const ['CITIZEN'],
    );
    expect(panels, {SmartPanel.citizen});
    expect(panels, isNot(contains(SmartPanel.department)));
  });

  test('visiblePanels shows both roles for dual JWT', () {
    final panels = RoleResolver.visiblePanels(
      const [
        SsoRoleMapping(roleType: 'CITIZEN', mappingSerialNo: 1),
        SsoRoleMapping(roleType: 'DEPARTMENT', mappingSerialNo: 2),
      ],
      jwtRoles: const ['CITIZEN', 'DEPARTMENT'],
    );
    expect(panels, containsAll([SmartPanel.citizen, SmartPanel.department]));
  });

  test('visiblePanels includes citizen and department for department JWT', () {
    final panels = RoleResolver.visiblePanels(
      const [
        SsoRoleMapping(roleType: 'DEPARTMENT', mappingSerialNo: 2),
        SsoRoleMapping(roleType: 'CITIZEN'),
      ],
      jwtRoles: const ['DEPARTMENT'],
    );
    expect(panels, containsAll([SmartPanel.citizen, SmartPanel.department]));
  });

  test('canSwitchPanels is false for citizen-only JWT roles', () {
    expect(
      RoleResolver.canSwitchPanels(
        const [SsoRoleMapping(roleType: 'CITIZEN', mappingSerialNo: 1)],
        jwtRoles: const ['CITIZEN'],
      ),
      isFalse,
    );
  });

  test('canSwitchPanels is true for department-only with synthetic citizen', () {
    expect(
      RoleResolver.canSwitchPanels(
        const [
          SsoRoleMapping(roleType: 'DEPARTMENT', mappingSerialNo: 2),
          SsoRoleMapping(roleType: 'CITIZEN'),
        ],
        jwtRoles: const ['DEPARTMENT'],
      ),
      isTrue,
    );
  });

  test('canSwitchPanels is true for dual JWT roles', () {
    expect(
      RoleResolver.canSwitchPanels(
        const [],
        jwtRoles: const ['CITIZEN', 'DEPARTMENT'],
      ),
      isTrue,
    );
  });

  test('canSwitchPanels is true for explicit DB citizen and department', () {
    expect(
      RoleResolver.canSwitchPanels(const [
        SsoRoleMapping(roleType: 'CITIZEN', mappingSerialNo: 1),
        SsoRoleMapping(roleType: 'DEPARTMENT', mappingSerialNo: 2),
      ]),
      isTrue,
    );
  });

  test('primaryPanel is CITIZEN for citizen-only JWT', () {
    expect(
      RoleResolver.primaryPanel(
        const [
          SsoRoleMapping(roleType: 'DEPARTMENT'),
          SsoRoleMapping(roleType: 'CITIZEN'),
        ],
        jwtRoles: const ['CITIZEN'],
      ),
      SmartPanel.citizen,
    );
  });

  test('primaryPanel is DEPARTMENT for department-only JWT', () {
    expect(
      RoleResolver.primaryPanel(
        const [
          SsoRoleMapping(roleType: 'DEPARTMENT', mappingSerialNo: 2),
          SsoRoleMapping(roleType: 'CITIZEN'),
        ],
        jwtRoles: const ['DEPARTMENT'],
      ),
      SmartPanel.department,
    );
  });

  test('hasPanel returns true for citizen with empty mappings', () {
    expect(RoleResolver.hasPanel(const [], SmartPanel.citizen), isTrue);
  });

  test('hasPanel returns false for department with empty mappings', () {
    expect(RoleResolver.hasPanel(const [], SmartPanel.department), isFalse);
  });
}
