import 'package:dio/dio.dart';

import '../../models/citizen_dashboard_counts.dart';
import '../api_exception.dart';
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
      final response = await _client.postForm(
        '/api/dashboard/commonDashboardCount',
        data: {
          'commonId': commonId,
          'userType': 'DEPARTMENT',
        },
        options: Options(extra: {'roleHeader': 'DEPARTMENT'}),
      );
      return _asMap(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  static Map<String, dynamic> unwrapDashboardData(Map<String, dynamic> data) {
    final status = data['status']?.toString().toUpperCase();
    if (status == 'ERROR' || status == 'NO_DATA') {
      throw ApiException(
        message: data['message']?.toString() ?? 'Dashboard data unavailable.',
        path: '/api/dashboard/commonDashboardCount',
      );
    }
    return data;
  }

  /// Case-insensitive lookup for JDBC-quoted keys (`TOTAL_SERVICE`, etc.).
  static String stringValue(Map<String, dynamic> data, String key) {
    final target = key.toUpperCase();
    for (final entry in data.entries) {
      if (entry.key.toUpperCase() == target) {
        final value = entry.value;
        if (value == null) return '0';
        return value.toString();
      }
    }
    return '0';
  }

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }
}
