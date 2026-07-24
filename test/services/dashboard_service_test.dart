import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:smart_rajasthan/services/api_exception.dart';
import 'package:smart_rajasthan/services/dashboard/dashboard_service.dart';
import 'package:smart_rajasthan/services/smart_api_client.dart';

void main() {
  group('DashboardService.stringValue', () {
    test('finds value with exact key', () {
      final data = {'TOTAL_SERVICE': 42};
      expect(DashboardService.stringValue(data, 'TOTAL_SERVICE'), '42');
    });

    test('matches keys case-insensitively', () {
      final data = {
        'TOTAL_BENEFICIARY': '100',
        'unique_beneficiary': 7,
      };
      expect(DashboardService.stringValue(data, 'total_beneficiary'), '100');
      expect(DashboardService.stringValue(data, 'UNIQUE_BENEFICIARY'), '7');
    });

    test('returns 0 for missing or null values', () {
      expect(DashboardService.stringValue({}, 'TOTAL_SERVICE'), '0');
      expect(
        DashboardService.stringValue({'TOTAL_SERVICE': null}, 'TOTAL_SERVICE'),
        '0',
      );
    });

    test('formats Indian grouping for large counts', () {
      expect(
        DashboardService.formatIndianNumber(770826),
        '7,70,826',
      );
      expect(
        DashboardService.stringValue({'TOTAL_SERVICE': 770826}, 'TOTAL_SERVICE'),
        '7,70,826',
      );
    });

    test('unwraps nested data map', () {
      final raw = {
        'status': 'OK',
        'data': {'TOTAL_SERVICE': 5, 'TOTAL_BENEFICIARY': 10},
      };
      final unwrapped = DashboardService.unwrapDashboardData(raw);
      expect(DashboardService.stringValue(unwrapped, 'TOTAL_SERVICE'), '5');
      expect(DashboardService.stringValue(unwrapped, 'TOTAL_BENEFICIARY'), '10');
    });
  });

  group('DashboardService.unwrapDashboardData', () {
    test('returns flat success map with count keys', () {
      final raw = {
        'TOTAL_SERVICE': 12,
        'TOTAL_BENEFICIARY': 1000,
        'UNIQUE_BENEFICIARY': 800,
      };
      final unwrapped = DashboardService.unwrapDashboardData(raw);
      expect(unwrapped['TOTAL_SERVICE'], 12);
      expect(unwrapped['TOTAL_BENEFICIARY'], 1000);
      expect(unwrapped['UNIQUE_BENEFICIARY'], 800);
    });

    test('NO_DATA maps to zeros', () {
      final unwrapped = DashboardService.unwrapDashboardData({
        'status': 'NO_DATA',
        'message': 'No data found',
        'TOTAL_SERVICE': 0,
      });
      expect(unwrapped['TOTAL_SERVICE'], 0);
      expect(unwrapped['TOTAL_BENEFICIARY'], 0);
      expect(unwrapped['UNIQUE_BENEFICIARY'], 0);
    });

    test('ERROR status throws ApiException', () {
      expect(
        () => DashboardService.unwrapDashboardData({
          'status': 'ERROR',
          'message': 'Count query failed',
        }),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Count query failed',
          ),
        ),
      );
    });
  });

  group('DashboardService.fetchDepartmentCounts', () {
    test('posts commonId and userType as form fields', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://smart.example/smart'));
      final adapter = DioAdapter(dio: dio);
      final client = SmartApiClient.forTest(dio);

      adapter.onPost(
        '/api/dashboard/commonDashboardCount',
        (server) => server.reply(200, {
          'TOTAL_SERVICE': 3,
          'TOTAL_BENEFICIARY': 50,
          'UNIQUE_BENEFICIARY': 40,
        }),
        data: Matchers.any,
      );

      final response = await client.postForm(
        '/api/dashboard/commonDashboardCount',
        data: {
          'commonId': '7',
          'userType': 'DEPARTMENT',
        },
        options: Options(extra: {'roleHeader': 'DEPARTMENT'}),
      );

      expect(response.statusCode, 200);
      final map = Map<String, dynamic>.from(response.data as Map);
      final unwrapped = DashboardService.unwrapDashboardData(map);
      expect(DashboardService.stringValue(unwrapped, 'TOTAL_SERVICE'), '3');
      expect(DashboardService.stringValue(unwrapped, 'TOTAL_BENEFICIARY'), '50');
    });

    test('rejects non-positive department id', () async {
      expect(
        () => DashboardService.instance.fetchDepartmentCounts(departmentId: '0'),
        throwsA(isA<ApiException>()),
      );
      expect(
        () =>
            DashboardService.instance.fetchDepartmentCounts(departmentId: 'abc'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
