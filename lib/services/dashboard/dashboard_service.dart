import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/app_logger.dart';
import '../../models/citizen_dashboard_counts.dart';
import '../smart_api_service.dart';
import '../smart_api_client.dart';

/// Dashboard API calls for citizen and department panels.
class DashboardService {
  DashboardService._();

  static final DashboardService instance = DashboardService._();

  final SmartApiService _api = SmartApiService.instance;
  final SmartApiClient _client = SmartApiClient.instance;

  Future<CitizenDashboardCounts> fetchCitizenCounts() =>
      _api.fetchCitizenDashboardCounts();

  /// Department KPIs — same contract as web `department/page.tsx`:
  /// `POST /api/dashboard/commonDashboardCount` with form fields
  /// `commonId` (MappedDept id) + `userType=DEPARTMENT`.
  Future<Map<String, dynamic>> fetchDepartmentCounts({
    required String departmentId,
  }) async {
    final commonId = int.tryParse(departmentId.trim());
    if (commonId == null || commonId <= 0) {
      throw ApiException(
        message: 'Select a valid department to view dashboard counts.',
        path: '/api/dashboard/commonDashboardCount',
      );
    }

    try {
      // Match web FormData string fields (Spring @RequestParam binds either
      // multipart or application/x-www-form-urlencoded).
      final response = await _client.postForm(
        '/api/dashboard/commonDashboardCount',
        data: {
          'commonId': commonId.toString(),
          'userType': 'DEPARTMENT',
        },
        options: Options(extra: {'roleHeader': 'DEPARTMENT'}),
      );
      if (kDebugMode) {
        AppLogger.d(
          'DashboardService',
          'commonDashboardCount commonId=$commonId '
          'status=${response.statusCode} bodyType=${response.data.runtimeType}',
        );
      }
      return _asMap(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Unwraps envelope / nested `data` while preserving count keys.
  static Map<String, dynamic> unwrapDashboardData(Map<String, dynamic> data) {
    final status = data['status']?.toString().toUpperCase();
    if (status == 'ERROR') {
      throw ApiException(
        message: data['message']?.toString() ??
            'Unable to load dashboard counts. Please try again later.',
        path: '/api/dashboard/commonDashboardCount',
      );
    }

    // NO_DATA / empty → treat as zeros (do not surface as UI failure).
    if (status == 'NO_DATA') {
      return const {
        'TOTAL_SERVICE': 0,
        'TOTAL_BENEFICIARY': 0,
        'UNIQUE_BENEFICIARY': 0,
      };
    }

    final nested = data['data'];
    if (nested is Map) {
      final nestedMap = Map<String, dynamic>.from(nested);
      if (_hasCountKey(nestedMap)) return nestedMap;
    }
    if (nested is List && nested.isNotEmpty && nested.first is Map) {
      final first = Map<String, dynamic>.from(nested.first as Map);
      if (_hasCountKey(first)) return first;
    }
    return data;
  }

  static bool _hasCountKey(Map<String, dynamic> map) {
    const keys = {
      'TOTAL_SERVICE',
      'TOTAL_BENEFICIARY',
      'UNIQUE_BENEFICIARY',
      'SCHEME_ONBOARD',
    };
    for (final entry in map.entries) {
      if (keys.contains(entry.key.toUpperCase())) return true;
    }
    return false;
  }

  /// Case-insensitive lookup for JDBC-quoted keys (`TOTAL_SERVICE`, etc.).
  static String stringValue(Map<String, dynamic> data, String key) {
    final target = key.toUpperCase();
    for (final entry in data.entries) {
      if (entry.key.toUpperCase() == target) {
        return formatIndianNumber(entry.value);
      }
    }
    // Nested fallback (e.g. `{ data: { TOTAL_SERVICE: 1 } }` when unwrap missed).
    final nested = data['data'];
    if (nested is Map) {
      for (final entry in nested.entries) {
        if (entry.key.toString().toUpperCase() == target) {
          return formatIndianNumber(entry.value);
        }
      }
    }
    return '0';
  }

  /// Matches web `formatIndianNumber` (en-IN grouping).
  static String formatIndianNumber(Object? val) {
    if (val == null || val == '') return '0';
    final numValue = val is num ? val.toDouble() : double.tryParse(val.toString());
    if (numValue == null || numValue.isNaN) return '0';
    final negative = numValue < 0;
    final abs = numValue.abs();
    final intPart = abs.truncate();
    final fraction = abs - intPart;
    final digits = intPart.toString();
    String grouped;
    if (digits.length <= 3) {
      grouped = digits;
    } else {
      final last3 = digits.substring(digits.length - 3);
      var rest = digits.substring(0, digits.length - 3);
      final parts = <String>[];
      while (rest.length > 2) {
        parts.insert(0, rest.substring(rest.length - 2));
        rest = rest.substring(0, rest.length - 2);
      }
      if (rest.isNotEmpty) parts.insert(0, rest);
      grouped = '${parts.join(',')},$last3';
    }
    var result = grouped;
    if (fraction > 0) {
      final fracStr = fraction.toStringAsFixed(2).substring(1); // ".xx"
      result = '$grouped$fracStr';
    }
    return negative ? '-$result' : result;
  }

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }
}
