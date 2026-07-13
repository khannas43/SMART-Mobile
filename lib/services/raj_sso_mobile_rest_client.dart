import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';
import '../config/sso_config.dart';
import '../models/raj_sso_mobile_auth_result.dart';
import '../utils/raj_sso_aes.dart';
import 'api_exception.dart';
import 'auth_messages.dart';

/// Raj SSO REST client — `SSOAuthenticationMobileNew` (Mobile API v2.6.1 §2.1).
class RajSsoMobileRestClient {
  RajSsoMobileRestClient._([Dio? dio])
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(seconds: 30),
                headers: {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            );

  static final RajSsoMobileRestClient instance = RajSsoMobileRestClient._();

  @visibleForTesting
  factory RajSsoMobileRestClient.forTest(Dio dio) =>
      RajSsoMobileRestClient._(dio);

  final Dio _dio;

  /// Authenticates via Raj SSO REST with AES-encrypted password.
  Future<RajSsoMobileAuthResult> authenticateMobile({
    required String userName,
    required String password,
    String? applicationName,
    String? encryptionKey,
  }) async {
    final ssoId = userName.trim();
    if (ssoId.isEmpty) {
      throw ApiException(message: AuthMessages.invalidCredentialsEn);
    }
    if (password.isEmpty) {
      throw ApiException(message: AuthMessages.invalidCredentialsEn);
    }

    final app = applicationName ?? SsoConfig.rajSsoMobileApplicationName;
    final key = encryptionKey ?? SsoConfig.rajSsoMobileEncryptionKey;
    final encryptedPassword = RajSsoAes.encryptPassword(password, key);

    final uri = SsoConfig.ssoAuthenticationMobileNewUri(Env.environment);
    final payload = {
      'Application': app,
      'UserName': ssoId,
      'Password': encryptedPassword,
    };
    final useFormUrlEncoded = usesFormUrlEncodedAuth(Env.isProd);

    try {
      final response = await _dio.post<dynamic>(
        uri.toString(),
        data: buildAuthRequestData(payload, useFormUrlEncoded: useFormUrlEncoded),
        options: buildAuthRequestOptions(useFormUrlEncoded: useFormUrlEncoded),
      );

      final data = response.data;
      if (data is! Map) {
        throw ApiException(
          message: AuthMessages.invalidCredentialsEn,
          path: uri.path,
          statusCode: response.statusCode,
        );
      }

      final map = Map<String, dynamic>.from(data);
      final result = RajSsoMobileAuthResult.fromJson(map);
      if (!result.valid) {
        throw ApiException(
          message: AuthMessages.invalidCredentialsEn,
          path: uri.path,
          statusCode: response.statusCode,
        );
      }

      return RajSsoMobileAuthResult(
        valid: true,
        message: result.message,
        ssoId: result.ssoId ?? ssoId,
        displayName: result.displayName,
        roles: result.roles,
        userType: result.userType,
        userStatus: result.userStatus,
        mobile: result.mobile,
        mailPersonal: result.mailPersonal,
        firstName: result.firstName,
        lastName: result.lastName,
        janaadhaarId: result.janaadhaarId,
        janaadhaarMemberId: result.janaadhaarMemberId,
        ssoToken: result.ssoToken,
        userdetails: result.userdetails,
      );
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException(
        message: _messageFromDio(e),
        path: uri.path,
        statusCode: e.response?.statusCode,
        kind: _kindFromDio(e),
        cause: e,
      );
    }
  }

  static ApiErrorKind _kindFromDio(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiErrorKind.network;
    }
    final code = e.response?.statusCode;
    if (code != null && code >= 500) return ApiErrorKind.server;
    return ApiErrorKind.client;
  }

  /// Production Raj SSO (v2.6.1 §66) requires form-urlencoded; UAT keeps JSON.
  @visibleForTesting
  static bool usesFormUrlEncodedAuth(bool isProd) => isProd;

  @visibleForTesting
  static Object buildAuthRequestData(
    Map<String, String> payload, {
    required bool useFormUrlEncoded,
  }) =>
      useFormUrlEncoded ? payload : jsonEncode(payload);

  @visibleForTesting
  static Options buildAuthRequestOptions({required bool useFormUrlEncoded}) =>
      Options(
        headers: {
          'Accept': 'application/json',
          'Content-Type': useFormUrlEncoded
              ? 'application/x-www-form-urlencoded'
              : 'application/json',
        },
      );

  static String _messageFromDio(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return AuthMessages.networkEn;
    }
    final code = e.response?.statusCode;
    if (code != null && code >= 500) {
      return AuthMessages.serviceUnavailableEn;
    }
    return AuthMessages.invalidCredentialsEn;
  }
}
