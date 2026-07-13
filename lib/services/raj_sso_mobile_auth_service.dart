import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../app_navigation.dart';
import '../config/sso_config.dart';
import '../core/app_logger.dart';
import '../models/raj_sso_mobile_auth_result.dart';
import 'api_exception.dart';
import 'auth_messages.dart';
import 'auth_service.dart';
import 'raj_sso_mobile_rest_client.dart';
import 'smart_api_client.dart';
import 'smart_api_service.dart';
import 'sso_landing_service.dart';

/// Raj SSO native login (REST API Mobile v2.6.1) → SMART JWT → home.
class RajSsoMobileAuthService {
  RajSsoMobileAuthService._({
    RajSsoMobileRestClient? restClient,
    SmartApiClient? smartClient,
    SsoLandingService? landingService,
    SmartApiService? profileService,
  })  : _rest = restClient ?? RajSsoMobileRestClient.instance,
        _smart = smartClient ?? SmartApiClient.instance,
        _landing = landingService ?? SsoLandingService.instance,
        _profiles = profileService ?? SmartApiService.instance;

  static final RajSsoMobileAuthService instance = RajSsoMobileAuthService._();

  @visibleForTesting
  factory RajSsoMobileAuthService.forTest({
    required RajSsoMobileRestClient restClient,
    required SmartApiClient smartClient,
    SsoLandingService? landingService,
    SmartApiService? profileService,
  }) =>
      RajSsoMobileAuthService._(
        restClient: restClient,
        smartClient: smartClient,
        landingService: landingService,
        profileService: profileService,
      );

  final RajSsoMobileRestClient _rest;
  final SmartApiClient _smart;
  final SsoLandingService _landing;
  final SmartApiService _profiles;

  static final _mintJwtOptions = Options(
    extra: {
      'skipAuthErrorHandling': true,
      'noRetry': true,
    },
    headers: {'Accept': 'application/json'},
    followRedirects: false,
    validateStatus: _acceptMintStatus,
  );

  static bool _acceptMintStatus(int? status) {
    if (status == null) return false;
    return status >= 200 && status < 500;
  }

  /// Full login: Raj SSO REST auth → SMART backend JWT → navigate home.
  Future<RajSsoMobileAuthResult> loginAndNavigateHome({
    required String ssoId,
    required String password,
  }) async {
    final auth = await _rest.authenticateMobile(
      userName: ssoId,
      password: password,
    );

    final resolvedSsoId = auth.ssoId?.trim();
    if (resolvedSsoId == null || resolvedSsoId.isEmpty) {
      throw ApiException(message: AuthMessages.invalidCredentialsEn);
    }

    final landing = await _mintSmartJwt(resolvedSsoId, auth);
    await AuthService.instance.saveToken(landing.token);

    try {
      await _profiles.fetchCitizenProfile(ssoId: resolvedSsoId);
    } catch (e) {
      AppLogger.d('RajSsoMobileAuth', 'Post-login getProfile skipped: $e');
    }

    AppNavigation.replaceWithHome();
    return auth;
  }

  Future<SsoLandingResult> _mintSmartJwt(
    String ssoId,
    RajSsoMobileAuthResult auth,
  ) async {
    final userdetails = auth.landingUserdetails?.trim();

    if (_isEncryptedSsoUserdetails(userdetails)) {
      try {
        return await _landing.exchangeUserdetails(
          userdetails: userdetails!,
          ssoId: ssoId,
        );
      } on ApiException catch (e) {
        AppLogger.d(
          'RajSsoMobileAuth',
          'Landing exchange failed (${e.statusCode}): ${e.message}',
        );
        if (e.isNetworkError) rethrow;
      }
    }

    if (userdetails != null &&
        userdetails.isNotEmpty &&
        !_isSyntheticUserdetails(userdetails)) {
      try {
        await _profiles.syncUserProfileFromSso(
          ssoId: ssoId,
          ssoToken: userdetails,
        );
      } catch (e) {
        AppLogger.d('RajSsoMobileAuth', 'GET /profile sync skipped: $e');
      }
    }

    try {
      final primary = await _tryMobileRestLogin(ssoId);
      if (primary != null) return primary;
    } on ApiException catch (e) {
      if (e.isNetworkError) rethrow;
      if (!_shouldFallbackAfterMobileRestFailure(e)) {
        throw ApiException(
          message: _mintFailureMessage(e),
          path: e.path,
          statusCode: e.statusCode,
          kind: e.kind,
          cause: e,
        );
      }
      if (kDebugMode) {
        debugPrint(
          'mobile-rest-login failed (${e.statusCode}): ${e.message} — trying landing fallback',
        );
      }
    }

    return _fallbackMintJwt(ssoId);
  }

  @visibleForTesting
  static bool isEncryptedSsoUserdetailsForTest(String? value) =>
      _isEncryptedSsoUserdetails(value);

  @visibleForTesting
  static bool _isEncryptedSsoUserdetails(String? value) {
    if (value == null) return false;
    final t = value.trim();
    if (t.length < 48) return false;
    if (_isSyntheticUserdetails(t)) return false;
    return RegExp(r'^[A-Za-z0-9+/=_\-]+$').hasMatch(t);
  }

  static bool _isSyntheticUserdetails(String value) =>
      value.startsWith('mobile-rest:') || value == 'sandbox';

  Future<SsoLandingResult?> _tryMobileRestLogin(String ssoId) async {
    try {
      final response = await _smart.post<dynamic>(
        SsoConfig.mobileRestLoginPath,
        queryParameters: {'ssoId': ssoId},
        options: _mintJwtOptions,
      );

      final status = response.statusCode;
      if (status == 404) return null;

      return _parseMintResponse(
        response.data,
        status,
        SsoConfig.mobileRestLoginPath,
      );
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDioException(e);
    }
  }

  SsoLandingResult? _parseMintResponse(
    Object? data,
    int? status, [
    String path = SsoConfig.mobileRestLoginPath,
  ]) {
    if (data is! Map) {
      throw ApiException(
        message: _mintFailureMessage(
          ApiException(
            message: '',
            path: path,
            statusCode: status,
          ),
        ),
        path: path,
        statusCode: status,
      );
    }

    final map = Map<String, dynamic>.from(data);
    final token = map['token']?.toString().trim();
    if (token != null && token.isNotEmpty) {
      return SsoLandingResult(
        token: token,
        currentSrole: map['currentSrole']?.toString(),
        redirectPath:
            map['redirectPath']?.toString() ?? map['redirectUrl']?.toString(),
      );
    }

    throw ApiException(
      message: _mintFailureMessage(
        ApiException(
          message: map['error']?.toString() ?? '',
          path: path,
          statusCode: status,
        ),
      ),
      path: path,
      statusCode: status,
    );
  }

  bool _shouldFallbackAfterMobileRestFailure(ApiException e) {
    if (e.isNetworkError) return false;
    final code = e.statusCode;
    return code == null || code == 404 || code >= 500;
  }

  Future<SsoLandingResult> _fallbackMintJwt(String ssoId) async {
    AppLogger.d('RajSsoMobileAuth', 'Using sandboxlanding fallback for $ssoId');
    try {
      return await _landing.exchangeUserdetails(
        userdetails: 'mobile-rest:$ssoId',
        ssoId: ssoId,
      );
    } on ApiException catch (e) {
      throw ApiException(
        message: _mintFailureMessage(e),
        path: e.path ?? SsoConfig.sandboxLandingPath,
        statusCode: e.statusCode,
        cause: e,
      );
    } catch (e) {
      throw ApiException(
        message: AuthMessages.invalidCredentialsEn,
        path: SsoConfig.sandboxLandingPath,
        cause: e,
      );
    }
  }

  static String _mintFailureMessage(ApiException e) {
    if (e.isNetworkError) return AuthMessages.networkEn;
    final code = e.statusCode;
    if (code != null && code >= 500) return AuthMessages.serviceUnavailableEn;
    return AuthMessages.invalidCredentialsEn;
  }
}
