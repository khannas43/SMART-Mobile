import 'package:dio/dio.dart';

import '../models/citizen_dashboard_counts.dart';
import '../models/citizen_profile.dart';
import 'auth_service.dart';
import 'smart_api_client.dart';

/// Citizen-facing SMART backend calls (profile, dashboard, auth helpers).
class SmartApiService {
  SmartApiService._();

  static final SmartApiService instance = SmartApiService._();

  final SmartApiClient _client = SmartApiClient.instance;

  /// UAT/dev helper — stores JWT via [AuthService.saveToken].
  Future<String> fetchSandboxToken({String userdetails = 'sandbox'}) async {
    final response = await _client.post(
      '/api/sso/getSandBoxToken',
      queryParameters: {'userdetails': userdetails},
      options: Options(
        extra: const {
          'skipAuthErrorHandling': true,
        },
      ),
    );

    final data = response.data;
    final token = data is Map ? data['token']?.toString() : null;
    if (token == null || token.trim().isEmpty) {
      throw ApiException(
        message: 'Sandbox token missing in response',
        path: '/api/sso/getSandBoxToken',
      );
    }

    await AuthService.instance.saveToken(token.trim());
    return token.trim();
  }

  /// Parsed citizen profile (activity 2.9).
  Future<CitizenProfile> fetchCitizenProfile({
    String? ssoId,
    String? userId,
  }) async {
    final auth = AuthService.instance;
    final resolvedSsoId = ssoId ?? auth.ssoId ?? '';
    if (resolvedSsoId.isEmpty && (userId ?? auth.smUserId ?? '').isEmpty) {
      throw ApiException(
        message: 'SSO ID required to load profile',
        path: '/api/sso/getProfile',
      );
    }

    final response = await _client.post(
      '/api/sso/getProfile',
      data: {
        'ssoId': resolvedSsoId,
        if ((userId ?? auth.smUserId)?.isNotEmpty == true)
          'userId': userId ?? auth.smUserId,
      },
    );

    final raw = _asMap(response.data);
    if (raw.isEmpty) {
      throw ApiException(
        message: 'Profile not found for this SSO account',
        path: '/api/sso/getProfile',
        statusCode: response.statusCode,
      );
    }

    final profile = CitizenProfile.fromApiMap(
      raw,
      ssoIdFallback: resolvedSsoId.isNotEmpty ? resolvedSsoId : auth.ssoId,
    );
    if (profile.isEmpty) {
      throw ApiException(
        message: 'Profile response did not contain citizen details',
        path: '/api/sso/getProfile',
        statusCode: response.statusCode,
      );
    }
    return profile;
  }

  /// `POST /api/sso/getProfile` — citizen profile fields (`NAME_EN`, etc.).
  Future<Map<String, dynamic>> getProfile({
    String? ssoId,
    String? userId,
  }) async {
    final profile = await fetchCitizenProfile(ssoId: ssoId, userId: userId);
    return profile.toApiMap();
  }

  /// `GET /api/sso/profile` — same as web: fetches Raj SSO profile and upserts USER_PROFILE.
  Future<void> syncUserProfileFromSso({
    required String ssoId,
    required String ssoToken,
  }) async {
    await _client.get<dynamic>(
      '/api/sso/profile',
      options: Options(
        headers: {
          'SSO-ID': ssoId,
          'SSO-TOKEN': ssoToken,
        },
        extra: const {'skipAuthErrorHandling': true},
      ),
    );
  }

  /// `POST /api/dashboard/citizenDashboardCount` — dashboard stat cards.
  Future<Map<String, dynamic>> getCitizenDashboardCount({
    String? ssoId,
    String? userId,
  }) async {
    final counts = await fetchCitizenDashboardCounts(ssoId: ssoId, userId: userId);
    return counts.toApiMap();
  }

  /// Parsed dashboard counts (activity 2.10).
  Future<CitizenDashboardCounts> fetchCitizenDashboardCounts({
    String? ssoId,
    String? userId,
  }) async {
    final auth = AuthService.instance;
    final resolvedSsoId = ssoId ?? auth.ssoId ?? '';
    final resolvedUserId = userId ?? auth.smUserId ?? '';
    if (resolvedSsoId.isEmpty && resolvedUserId.isEmpty) {
      throw ApiException(
        message: 'SSO ID or member ID required for dashboard counts',
        path: '/api/dashboard/citizenDashboardCount',
      );
    }

    try {
      final response = await _client.postForm(
        '/api/dashboard/citizenDashboardCount',
        data: {
          'ssoId': resolvedSsoId,
          'userId': resolvedUserId,
        },
        options: Options(extra: {'roleHeader': 'CITIZEN'}),
      );

      final raw = _asMap(response.data);
      final status = raw['status']?.toString().toUpperCase();
      if (status == 'ERROR') {
        throw ApiException(
          message: raw['message']?.toString() ?? 'Dashboard count request failed',
          path: '/api/dashboard/citizenDashboardCount',
          statusCode: response.statusCode,
        );
      }

      return CitizenDashboardCounts.fromApiMap(raw);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }
}
