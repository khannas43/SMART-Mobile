import '../../models/auth_session.dart';
import '../../models/sso_role_mapping.dart';
import '../../models/user_role.dart';

/// Resolves available panels from SSO role mappings.
class RoleResolver {
  RoleResolver._();

  /// Home panel when the user cannot switch (single-role accounts).
  static SmartPanel primaryPanel(
    List<SsoRoleMapping> mappings, {
    AuthSession? session,
    List<String>? jwtRoles,
  }) {
    if (hasCitizenRole(mappings, session: session, jwtRoles: jwtRoles) &&
        !hasDepartmentRole(mappings, session: session, jwtRoles: jwtRoles)) {
      return SmartPanel.citizen;
    }
    if (hasDepartmentRole(mappings, session: session, jwtRoles: jwtRoles) &&
        !hasCitizenRole(mappings, session: session, jwtRoles: jwtRoles)) {
      return SmartPanel.department;
    }
    return defaultPanel(mappings);
  }

  /// Show panel switcher for department users (department-only or dual-role).
  /// Hidden for citizen-only accounts.
  static bool canSwitchPanels(
    List<SsoRoleMapping> mappings, {
    AuthSession? session,
    List<String>? jwtRoles,
  }) {
    return hasDepartmentRole(
      mappings,
      session: session,
      jwtRoles: jwtRoles,
    );
  }

  /// Panels the user may access.
  /// Citizen-only: citizen only. Department / dual: citizen + department.
  static Set<SmartPanel> visiblePanels(
    List<SsoRoleMapping> mappings, {
    AuthSession? session,
    List<String>? jwtRoles,
  }) {
    final citizen = hasCitizenRole(
      mappings,
      session: session,
      jwtRoles: jwtRoles,
    );
    final department = hasDepartmentRole(
      mappings,
      session: session,
      jwtRoles: jwtRoles,
    );

    if (department) {
      return {SmartPanel.citizen, SmartPanel.department};
    }
    if (citizen) {
      return {SmartPanel.citizen};
    }
    return {SmartPanel.citizen};
  }

  static bool hasCitizenRole(
    List<SsoRoleMapping> mappings, {
    AuthSession? session,
    List<String>? jwtRoles,
  }) {
    final roles = _roleNames(session, jwtRoles);
    if (roles.contains('CITIZEN')) return true;
    return mappings.any(
      (m) => m.roleTypeUpper == 'CITIZEN' && m.mappingSerialNo != null,
    );
  }

  static bool hasDepartmentRole(
    List<SsoRoleMapping> mappings, {
    AuthSession? session,
    List<String>? jwtRoles,
  }) {
    final roles = _roleNames(session, jwtRoles);
    if (roles.contains('DEPARTMENT') || roles.contains('SUPER_ADMIN')) {
      return true;
    }
    return mappings.any(
      (m) => m.roleTypeUpper == 'DEPARTMENT' && m.mappingSerialNo != null,
    );
  }

  static Set<String> _roleNames(
    AuthSession? session,
    List<String>? jwtRoles,
  ) {
    return {
      for (final role in _jwtRoleNames(session, jwtRoles)) role,
    };
  }

  static Iterable<String> _jwtRoleNames(
    AuthSession? session,
    List<String>? jwtRoles,
  ) sync* {
    if (jwtRoles != null) {
      for (final role in jwtRoles) {
        final upper = role.toUpperCase();
        if (upper.isNotEmpty) yield upper;
      }
      return;
    }
    if (session == null) return;
    for (final role in session.smartRoles) {
      final upper = role.toUpperCase();
      if (upper.isNotEmpty) yield upper;
    }
    for (final role in session.panelTypes) {
      final upper = role.toUpperCase();
      if (upper.isNotEmpty) yield upper;
    }
  }

  /// Default landing panel: Department when available, else Citizen.
  static SmartPanel defaultPanel(List<SsoRoleMapping> mappings) {
    if (mappings.any((m) => m.panel == SmartPanel.department)) {
      return SmartPanel.department;
    }
    return SmartPanel.citizen;
  }

  /// @deprecated Use [visiblePanels] for JWT-aware panel list.
  static Set<SmartPanel> availablePanels(List<SsoRoleMapping> mappings) {
    return visiblePanels(mappings);
  }

  static bool hasPanel(List<SsoRoleMapping> mappings, SmartPanel panel) {
    return visiblePanels(mappings).contains(panel);
  }
}
