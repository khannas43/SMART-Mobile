import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/auth_session.dart';
import 'api_exception.dart';
import 'auth_service.dart';
import 'smart_api_client.dart';
import 'smart_api_service.dart';

/// Parsed send-OTP response from `/api/CitizenConsent/sendConsentOTP`.
class ConsentOtpSendResult {
  const ConsentOtpSendResult({
    required this.transactionId,
    this.otpPrefix,
    this.maskedMobile,
    this.message,
  });

  final String transactionId;
  final String? otpPrefix;
  final String? maskedMobile;
  final String? message;
}

/// Parsed validate-OTP response from `/api/CitizenConsent/validateConsentOTP`.
class ConsentOtpValidateResult {
  const ConsentOtpValidateResult({
    required this.valid,
    this.message,
    this.raw = const {},
  });

  final bool valid;
  final String? message;
  final Map<String, dynamic> raw;
}

/// OTP flow for Provide Consent (`CitizenConsentController`).
class ConsentOtpService {
  ConsentOtpService._([SmartApiClient? client])
      : _client = client ?? SmartApiClient.instance;

  static final ConsentOtpService instance = ConsentOtpService._();

  @visibleForTesting
  factory ConsentOtpService.forTest(SmartApiClient client) =>
      ConsentOtpService._(client);

  final SmartApiClient _client;

  static final _citizenOptions = Options(extra: {'roleHeader': 'CITIZEN'});

  /// Blocks send when SSO profile lacks Jan Aadhaar linkage required at verify.
  static Future<String?> consentProfileBlockReason({AuthSession? session}) async {
    final active = session ?? AuthService.instance.session;
    if (active == null) {
      return 'Please sign in again.';
    }

    try {
      final profile = await SmartApiService.instance.fetchCitizenProfile(
        ssoId: active.ssoId,
      );
      if (profile.janAadhaar.trim().isEmpty || profile.janMember.trim().isEmpty) {
        return 'Please update your Jan Aadhaar and Member ID in your SSO profile';
      }
      return null;
    } catch (_) {
      return _jwtProfileBlockReason(active);
    }
  }

  static String? _jwtProfileBlockReason(AuthSession session) {
    final smUserId = session.smUserId?.trim();
    final jfId = session.jfId?.trim();
    if (smUserId == null ||
        smUserId.isEmpty ||
        jfId == null ||
        jfId.isEmpty) {
      return 'Please update your Jan Aadhaar and Member ID in your SSO profile';
    }
    return null;
  }

  Future<ConsentOtpSendResult> sendOtp({required String consentId}) async {
    if (consentId.trim().isEmpty) {
      throw ApiException(
        message: 'Eligible service record is missing.',
        path: '/api/CitizenConsent/sendConsentOTP',
      );
    }

    try {
      final response = await _client.get<dynamic>(
        '/api/CitizenConsent/sendConsentOTP',
        queryParameters: {'consentId': consentId.trim()},
        options: _citizenOptions,
      );
      return parseSendResponse(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ConsentOtpValidateResult> validateOtp({
    required String tid,
    required String otp,
    String? otpPrefix,
  }) async {
    final trimmedTid = tid.trim();
    final trimmedOtp = otp.trim();
    final trimmedPrefix = otpPrefix?.trim();

    if (trimmedTid.isEmpty) {
      throw ApiException(
        message: 'OTP session expired. Please resend OTP.',
        path: '/api/CitizenConsent/validateConsentOTP',
      );
    }

    if (trimmedPrefix == null || trimmedPrefix.isEmpty) {
      throw ApiException(
        message: 'OTP session incomplete. Please resend OTP.',
        path: '/api/CitizenConsent/validateConsentOTP',
      );
    }

    try {
      final response = await _client.get<dynamic>(
        '/api/CitizenConsent/validateConsentOTP',
        queryParameters: {
          'tid': trimmedTid,
          'transactionId': trimmedTid,
          'otp': trimmedOtp,
          'otpPrefix': trimmedPrefix,
        },
        options: _citizenOptions,
      );
      return parseValidateResponse(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @visibleForTesting
  static ConsentOtpSendResult parseSendResponse(Object? data) {
    final map = _unwrap(data);
    final status = map['status']?.toString().toUpperCase();
    final statusCode = map['statusCode'];
    final failed = status == 'FAILED' ||
        (statusCode is num && statusCode.toInt() == 400);

    if (failed) {
      throw ApiException(
        message: map['message']?.toString().trim().isNotEmpty == true
            ? map['message'].toString().trim()
            : 'Failed to send OTP',
        path: '/api/CitizenConsent/sendConsentOTP',
        statusCode: statusCode is num ? statusCode.toInt() : 400,
      );
    }

    final transactionId = map['transactionId']?.toString() ??
        map['tid']?.toString() ??
        '';
    if (transactionId.isEmpty) {
      throw ApiException(
        message: map['message']?.toString().trim().isNotEmpty == true
            ? map['message'].toString().trim()
            : 'Failed to send OTP',
        path: '/api/CitizenConsent/sendConsentOTP',
      );
    }

    return ConsentOtpSendResult(
      transactionId: transactionId,
      otpPrefix: map['otpPrefix']?.toString(),
      maskedMobile: map['mobile']?.toString(),
      message: map['message']?.toString(),
    );
  }

  @visibleForTesting
  static ConsentOtpValidateResult parseValidateResponse(Object? data) {
    final map = _unwrap(data);
    if (_isValidateSuccess(map)) {
      return ConsentOtpValidateResult(
        valid: true,
        message: map['message']?.toString(),
        raw: map,
      );
    }

    throw ApiException(
      message: map['message']?.toString().trim().isNotEmpty == true
          ? map['message'].toString().trim()
          : 'OTP validation failed. Please try again.',
      path: '/api/CitizenConsent/validateConsentOTP',
      statusCode: 400,
    );
  }

  @visibleForTesting
  static bool _isValidateSuccess(Map<String, dynamic> map) {
    if (map['status'] == true || map['isvalidate'] == true) {
      return true;
    }
    final status = map['status']?.toString().toUpperCase();
    return status == 'SUCCESS';
  }

  static Map<String, dynamic> _unwrap(Object? data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is Map) return Map<String, dynamic>.from(nested);
      return data;
    }
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  /// Legacy helper — prefer [ConsentOtpSendResult.transactionId].
  String? extractTransactionId(Map<String, dynamic> sendResponse) {
    return sendResponse['transactionId']?.toString() ??
        sendResponse['tid']?.toString();
  }
}
