import 'user_role.dart';

/// SSO role mapping from GET /api/sso/role-mappings.
class SsoRoleMapping {
  const SsoRoleMapping({
    this.mappingSerialNo,
    this.memberSsoId,
    this.memberName,
    this.memberDepartment,
    this.memberDesignation,
    this.memberOfficeName,
    this.memberContactNo,
    this.memberEmailId,
    this.memberRoleId,
    this.roleId,
    this.roleName,
    this.roleType,
    this.panelType,
    this.accessLevel,
    this.departmentId,
    this.levelId,
    this.stateId,
    this.districtIds,
    this.blockIds,
    this.serviceIds,
    this.ticketVisibilityScope,
  });

  final int? mappingSerialNo;
  final String? memberSsoId;
  final String? memberName;
  final String? memberDepartment;
  final String? memberDesignation;
  final String? memberOfficeName;
  final int? memberContactNo;
  final String? memberEmailId;
  final int? memberRoleId;
  final int? roleId;
  final String? roleName;
  final String? roleType;
  final String? panelType;
  final String? accessLevel;
  final int? departmentId;
  final int? levelId;
  final int? stateId;
  final String? districtIds;
  final String? blockIds;
  final String? serviceIds;
  final String? ticketVisibilityScope;

  String get roleTypeUpper => (roleType ?? 'CITIZEN').toUpperCase();

  /// Admin roles are excluded from mobile — only citizen and department panels.
  SmartPanel? get panel => switch (roleTypeUpper) {
        'ADMIN' || 'SUPER_ADMIN' => null,
        'DEPARTMENT' => SmartPanel.department,
        'CITIZEN' => SmartPanel.citizen,
        _ => null,
      };

  factory SsoRoleMapping.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    return SsoRoleMapping(
      mappingSerialNo: asInt(json['mappingSerialNo']),
      memberSsoId: json['memberSsoId']?.toString(),
      memberName: json['memberName']?.toString(),
      memberDepartment: json['memberDepartment']?.toString(),
      memberDesignation: json['memberDesignation']?.toString(),
      memberOfficeName: json['memberOfficeName']?.toString(),
      memberContactNo: asInt(json['memberContactNo']),
      memberEmailId: json['memberEmailId']?.toString(),
      memberRoleId: asInt(json['memberRoleId']),
      roleId: asInt(json['roleId']),
      roleName: json['roleName']?.toString(),
      roleType: json['roleType']?.toString(),
      panelType: json['panelType']?.toString(),
      accessLevel: json['accessLevel']?.toString(),
      departmentId: asInt(json['departmentId']),
      levelId: asInt(json['levelId']),
      stateId: asInt(json['stateId']),
      districtIds: json['districtIds']?.toString(),
      blockIds: json['blockIds']?.toString(),
      serviceIds: json['serviceIds']?.toString(),
      ticketVisibilityScope: json['ticketVisibilityScope']?.toString(),
    );
  }

  static List<SsoRoleMapping> listFromResponse(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => SsoRoleMapping.fromJson(Map<String, dynamic>.from(e)))
        .where((m) => m.panel != null)
        .toList();
  }
}
