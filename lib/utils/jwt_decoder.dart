import 'dart:convert';

/// Lightweight JWT payload decode (no signature verification — server validates).
class JwtDecoder {
  JwtDecoder._();

  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(decoded);

      if (json is Map<String, dynamic>) return json;
      if (json is Map) return Map<String, dynamic>.from(json);
      return null;
    } catch (_) {
      return null;
    }
  }

  static String? claimAsString(Map<String, dynamic>? payload, String key) {
    final value = payload?[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
