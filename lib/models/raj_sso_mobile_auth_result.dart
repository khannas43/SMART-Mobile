/// Parsed response from Raj SSO `SSOAuthenticationMobileNew` (v2.6.1 §2.1).
class RajSsoMobileAuthResult {
  const RajSsoMobileAuthResult({
    required this.valid,
    required this.message,
    this.ssoId,
    this.displayName,
    this.roles = const [],
    this.userType,
    this.userStatus,
    this.mobile,
    this.mailPersonal,
    this.firstName,
    this.lastName,
    this.janaadhaarId,
    this.janaadhaarMemberId,
    this.ssoToken,
    this.userdetails,
  });

  factory RajSsoMobileAuthResult.fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['roles'];
    final roles = <String>[];
    if (rolesRaw is List) {
      for (final item in rolesRaw) {
        if (item != null) roles.add(item.toString());
      }
    }

    final token = _resolveLandingToken(json);

    return RajSsoMobileAuthResult(
      valid: json['valid'] == true,
      message: json['message']?.toString() ?? '',
      ssoId: json['SSOID']?.toString() ?? json['UserName']?.toString(),
      displayName: json['displayName']?.toString(),
      roles: roles,
      userType: json['userType']?.toString(),
      userStatus: json['userStatus']?.toString(),
      mobile: json['mobile']?.toString(),
      mailPersonal: json['mailPersonal']?.toString(),
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      janaadhaarId: json['janaadhaarId']?.toString(),
      janaadhaarMemberId: json['janaadhaarMemberId']?.toString(),
      ssoToken: token,
      userdetails: token,
    );
  }

  static String? _firstNonEmpty(List<dynamic> values) {
    for (final v in values) {
      final s = v?.toString().trim();
      if (s != null && s.isNotEmpty) return s;
    }
    return null;
  }

  /// Prefer explicit SSO token fields; ignore short/generic `token` values.
  static String? _resolveLandingToken(Map<String, dynamic> json) {
    final explicit = _firstNonEmpty([
      json['userdetails'],
      json['UserDetails'],
      json['SSO-TOKEN'],
      json['ssoToken'],
      json['SSOToken'],
    ]);
    if (explicit != null) return explicit;

    final generic = json['token']?.toString().trim();
    if (generic != null &&
        generic.length >= 48 &&
        RegExp(r'^[A-Za-z0-9+/=_\-]+$').hasMatch(generic)) {
      return generic;
    }
    return null;
  }

  final bool valid;
  final String message;
  final String? ssoId;
  final String? displayName;
  final List<String> roles;
  final String? userType;
  final String? userStatus;
  final String? mobile;
  final String? mailPersonal;
  final String? firstName;
  final String? lastName;
  final String? janaadhaarId;
  final String? janaadhaarMemberId;

  /// Raj SSO token for `GET /api/sso/profile` or `/landing` exchange.
  final String? ssoToken;

  /// Encrypted userdetails for `/landing` (same as web SSO callback).
  final String? userdetails;

  /// Best available token for profile save + JWT landing exchange.
  String? get landingUserdetails => userdetails ?? ssoToken;
}
