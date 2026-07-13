import '../utils/jwt_decoder.dart';

/// Decoded SMART JWT claims (activity 2.7).
class AuthSession {
  const AuthSession({
    required this.token,
    required this.payload,
  });

  final String token;
  final Map<String, dynamic> payload;

  static AuthSession? fromToken(String? token) {
    if (token == null || token.trim().isEmpty) return null;
    final trimmed = token.trim();
    final payload = JwtDecoder.decodePayload(trimmed);
    if (payload == null) return null;
    return AuthSession(token: trimmed, payload: payload);
  }

  String? get ssoId => JwtDecoder.claimAsString(payload, 'ssoId');

  String? get smUserId => JwtDecoder.claimAsString(payload, 'smUserId');

  String? get userName => JwtDecoder.claimAsString(payload, 'Name');

  String? get janRole => JwtDecoder.claimAsString(payload, 'JanRole');

  String? get jfId => JwtDecoder.claimAsString(payload, 'jfId');

  String? get userType => JwtDecoder.claimAsString(payload, 'userType');

  /// Uppercased to match web `authStore.currentSrole` / `X-Current-Role` header.
  String get currentRole {
    final fromToken = JwtDecoder.claimAsString(payload, 'currentSrole');
    return (fromToken ?? 'citizen').toUpperCase();
  }

  List<String> get panelTypes {
    final raw = payload['panelTypes'];
    if (raw is! List) return const ['CITIZEN'];
    return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }

  /// JWT `SmartRole` claim (string or array) — matches web authStore.
  List<String> get smartRoles {
    final raw = payload['SmartRole'] ?? payload['smartRole'];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return [raw.trim()];
    }
    return const [];
  }

  String? get departmentCode {
    return JwtDecoder.claimAsString(payload, 'departmentId');
  }

  int? get departmentId {
    final raw = payload['departmentId'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  int? get levelId {
    final raw = payload['levelId'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  String? get districtIds => JwtDecoder.claimAsString(payload, 'districtIds');

  String? get blockIds => JwtDecoder.claimAsString(payload, 'blockIds');

  /// Encrypted Raj SSO `userdetails` stored as JWT `sub` — required for `/sso/signout` (3.9).
  String? get userdetailsForSignOut => JwtDecoder.claimAsString(payload, 'sub');

  bool get isExpired {
    final at = expiresAt;
    if (at == null) return false;
    return DateTime.now().isAfter(at);
  }

  DateTime? get expiresAt {
    final exp = payload['exp'];
    if (exp is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
  }
}
