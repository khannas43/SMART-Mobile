import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';
import '../config/sso_config.dart';
import 'auth_service.dart';
import 'smart_api_client.dart';

/// Result of exchanging Raj SSO `userdetails` for a SMART JWT (activity 3.7).
class SsoLandingResult {
  const SsoLandingResult({
    required this.token,
    this.currentSrole,
    this.redirectPath,
  });

  final String token;
  final String? currentSrole;
  final String? redirectPath;
}

typedef SsoLandingExchange = Future<SsoLandingResult> Function({
  required String userdetails,
  String? ssoId,
});

/// Exchanges SSO callback `userdetails` via backend landing APIs.
class SsoLandingService {
  SsoLandingService._([SmartApiClient? client])
      : _client = client ?? SmartApiClient.instance;

  static final SsoLandingService instance = SsoLandingService._();

  @visibleForTesting
  factory SsoLandingService.forTest(SmartApiClient client) =>
      SsoLandingService._(client);

  final SmartApiClient _client;

  static final _landingOptions = Options(
    extra: {
      'skipAuthErrorHandling': true,
      'noRetry': true,
    },
    headers: {
      'Accept': 'application/json',
    },
    followRedirects: false,
    validateStatus: _acceptLandingStatus,
  );

  static bool _acceptLandingStatus(int? status) {
    if (status == null) return false;
    return status >= 200 && status < 500;
  }

  /// Validates SSO callback, exchanges for JWT, persists via [AuthService].
  Future<SsoLandingResult> completeLogin({
    required String userdetails,
    String? ssoId,
  }) async {
    final trimmed = userdetails.trim();
    if (trimmed.isEmpty) {
      throw ApiException(
        message: 'SSO callback did not include user details.',
        path: SsoConfig.landingPath,
      );
    }

    final result = await exchangeUserdetails(
      userdetails: trimmed,
      ssoId: ssoId,
    );
    await AuthService.instance.saveToken(result.token);
    return result;
  }

  /// Tries `/mobile-landing` JSON, then environment landing + Set-Cookie (3.7a).
  ///
  /// Native REST login fallback (`mobile-rest:{ssoId}`) always uses
  /// `/sandboxlanding` on every environment — same as UAT, no backend change.
  Future<SsoLandingResult> exchangeUserdetails({
    required String userdetails,
    String? ssoId,
  }) async {
    final trimmed = userdetails.trim();
    final isMobileRestFallback = _isMobileRestFallbackToken(trimmed);

    if (!isMobileRestFallback) {
      final mobile = await _tryMobileLanding(trimmed);
      if (mobile != null) return mobile;
    }

    final path = isMobileRestFallback
        ? SsoConfig.sandboxLandingPath
        : _landingPathForEnvironment();
    final query = <String, dynamic>{
      'userdetails': trimmed,
      if (isMobileRestFallback || _usesSandboxLanding)
        'ssoId': ssoId?.trim() ?? '',
    };

    final response = await _client.post<dynamic>(
      path,
      queryParameters: query,
      options: _landingOptions,
    );

    final fromBody = _tokenFromBody(response.data);
    if (fromBody != null) {
      return SsoLandingResult(
        token: fromBody.token,
        currentSrole: fromBody.currentSrole,
        redirectPath: fromBody.redirectPath,
      );
    }

    final fromCookie = jwtFromSetCookieHeaders(response.headers);
    if (fromCookie != null && fromCookie.isNotEmpty) {
      return SsoLandingResult(
        token: fromCookie,
        redirectPath: _redirectUrlFromLandingBody(response.data),
      );
    }

    final status = response.statusCode;
    throw ApiException(
      message: status == 401
          ? 'Raj SSO session was rejected. Please sign in again.'
          : 'Could not obtain SMART login token from the server.',
      path: path,
      statusCode: status,
    );
  }

  bool get _usesSandboxLanding =>
      Env.isUat || Env.isDev || !Env.isProd;

  String _landingPathForEnvironment() {
    if (Env.isProd) return SsoConfig.landingPath;
    return SsoConfig.sandboxLandingPath;
  }

  static bool _isMobileRestFallbackToken(String userdetails) =>
      userdetails.startsWith('mobile-rest:') || userdetails == 'sandbox';

  Future<SsoLandingResult?> _tryMobileLanding(String userdetails) async {
    try {
      final response = await _client.post<dynamic>(
        SsoConfig.mobileLandingPath,
        queryParameters: {'userdetails': userdetails},
        options: _landingOptions,
      );
      if (response.statusCode == 404) return null;

      final parsed = _tokenFromBody(response.data);
      if (parsed != null) {
        return SsoLandingResult(
          token: parsed.token,
          currentSrole: parsed.currentSrole,
          redirectPath: parsed.redirectPath,
        );
      }

      final fromCookie = jwtFromSetCookieHeaders(response.headers);
      if (fromCookie != null) {
        return SsoLandingResult(token: fromCookie);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
    return null;
  }

  static _BodyToken? _tokenFromBody(Object? data) {
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    final token = map['token']?.toString().trim();
    if (token == null || token.isEmpty) return null;
    return _BodyToken(
      token: token,
      currentSrole: map['currentSrole']?.toString(),
      redirectPath: map['redirectUrl']?.toString() ?? map['redirectPath']?.toString(),
    );
  }

  static String? _redirectUrlFromLandingBody(Object? data) {
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    return map['redirectUrl']?.toString() ?? map['redirectPath']?.toString();
  }

  /// Parses `Set-Cookie: jwt=...` from landing responses (activity 3.7a).
  static String? jwtFromSetCookieHeaders(Headers headers) {
    final values = headers.map['set-cookie'] ?? headers.map['Set-Cookie'];
    if (values == null || values.isEmpty) return null;

    for (final raw in values) {
      final token = _jwtFromCookieHeaderValue(raw);
      if (token != null) return token;
    }
    return null;
  }

  static String? _jwtFromCookieHeaderValue(Object? raw) {
    if (raw == null) return null;

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final direct = map['jwt']?.toString().trim();
      if (direct != null && direct.isNotEmpty) return direct;
      for (final entry in map.entries) {
        if (entry.key.toLowerCase() == 'jwt') {
          final value = entry.value?.toString().trim();
          if (value != null && value.isNotEmpty) return value;
        }
      }
      return null;
    }

    final header = raw.toString();
    if (header.isEmpty) return null;

    for (final part in header.split(';')) {
      final trimmed = part.trim();
      if (trimmed.startsWith('jwt=')) {
        final value = trimmed.substring(4).trim();
        return value.isEmpty ? null : value;
      }
    }
    return null;
  }
}

class _BodyToken {
  const _BodyToken({
    required this.token,
    this.currentSrole,
    this.redirectPath,
  });

  final String token;
  final String? currentSrole;
  final String? redirectPath;
}
