import '../../core/app_logger.dart';
import '../../models/auth_session.dart';
import '../../models/sso_role_mapping.dart';
import '../../models/user_role.dart';
import '../auth_service.dart';
import '../smart_api_client.dart';

/// Fetches SSO role mappings from backend (never queries DB directly).
class RoleMappingService {
  RoleMappingService._();

  static final RoleMappingService instance = RoleMappingService._();

  final SmartApiClient _client = SmartApiClient.instance;

  static const _adminRoles = {'ADMIN', 'SUPER_ADMIN'};

  /// Loads mappings from API; falls back to JWT claims when API is unavailable.
  Future<List<SsoRoleMapping>> loadMappings({AuthSession? session}) async {
    final active = session ?? AuthService.instance.session;
    if (active == null) {
      return mappingsFromJwt(const AuthSession(token: '', payload: {}));
    }

    final ssoId = active.ssoId;
    if (ssoId == null || ssoId.isEmpty) {
      return mappingsFromJwt(active);
    }

    try {
      return await fetchMappings(ssoId);
    } catch (e) {
      AppLogger.d(
        'RoleMappingService',
        'role-mappings unavailable; using JWT fallback: $e',
      );
      return mappingsFromJwt(active);
    }
  }

  Future<List<SsoRoleMapping>> fetchMappings(String ssoId) async {
    final response = await _client.get<dynamic>(
      '/api/sso/role-mappings',
      queryParameters: {'ssoId': ssoId},
    );
    final mappings = SsoRoleMapping.listFromResponse(response.data);
    AppLogger.d('RoleMappingService', 'Loaded ${mappings.length} mappings');
    return _ensureCitizen(mappings);
  }

  /// Builds role rows from JWT when `/role-mappings` is not deployed yet.
  List<SsoRoleMapping> mappingsFromJwt(AuthSession session) {
    final roles = <String>{...session.panelTypes, ...session.smartRoles}
        .map((r) => r.toUpperCase())
        .where((r) => r.isNotEmpty && !_adminRoles.contains(r))
        .toSet();

    if (!roles.contains('CITIZEN')) {
      roles.add('CITIZEN');
    }

    final levelId = session.levelId;
    final districtIds = session.districtIds;
    final blockIds = session.blockIds;
    final departmentId = session.departmentId;

    final mappings = <SsoRoleMapping>[];
    for (final role in roles) {
      if (_adminRoles.contains(role)) continue;
      final isDept = role == 'DEPARTMENT';
      mappings.add(
        SsoRoleMapping(
          memberSsoId: session.ssoId,
          memberName: session.userName,
          roleType: role,
          panelType: role,
          levelId: isDept ? levelId : null,
          districtIds: isDept ? districtIds : null,
          blockIds: isDept ? blockIds : null,
          departmentId: isDept ? departmentId : null,
        ),
      );
    }

    return _ensureCitizen(mappings);
  }

  List<SsoRoleMapping> _ensureCitizen(List<SsoRoleMapping> mappings) {
    final filtered = mappings.where((m) => m.panel != null).toList();
    if (filtered.any((m) => m.roleTypeUpper == 'CITIZEN')) {
      return filtered;
    }
    return [
      ...filtered,
      const SsoRoleMapping(roleType: 'CITIZEN', panelType: 'CITIZEN'),
    ];
  }

  static SmartPanel? panelForRole(String role) {
    return switch (role.toUpperCase()) {
      'ADMIN' || 'SUPER_ADMIN' => null,
      'DEPARTMENT' => SmartPanel.department,
      'CITIZEN' => SmartPanel.citizen,
      _ => null,
    };
  }
}
