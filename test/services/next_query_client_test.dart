import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:smart_rajasthan/services/api_exception.dart';
import 'package:smart_rajasthan/services/next_query_client.dart';
import 'package:smart_rajasthan/services/smart_api_client.dart';

void main() {
  group('NextQueryResult.fromResponse', () {
    test('parses rows and total from map', () {
      final result = NextQueryResult.fromResponse({
        'rows': [
          {'id': '1', 'nameEn': 'Scheme A'},
          {'id': '2', 'nameEn': 'Scheme B'},
        ],
        'total': 42,
      });

      expect(result.rows.length, 2);
      expect(result.total, 42);
      expect(result.rows.first['nameEn'], 'Scheme A');
    });

    test('returns empty result for non-map payload', () {
      final result = NextQueryResult.fromResponse('invalid');
      expect(result.rows, isEmpty);
      expect(result.total, 0);
    });
  });

  group('NextQueryClient', () {
    late Dio dio;
    late DioAdapter adapter;
    late NextQueryClient client;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://smarttest.example/smart'));
      adapter = DioAdapter(dio: dio);
      dio.httpClientAdapter = adapter;
      client = NextQueryClient.forTest(SmartApiClient.forTest(dio));
    });

    test('listCount posts model, fields, filters to list-count endpoint', () async {
      Map<String, dynamic>? capturedBody;

      adapter.onPost(
        '/api/nextquery/EligibleServices/list-count',
        (server) {
          server.replyCallback(200, (requestOptions) {
            capturedBody = requestOptions.data as Map<String, dynamic>?;
            return {
              'rows': <Map<String, dynamic>>[],
              'total': 7,
            };
          });
        },
        data: Matchers.any,
      );

      final result = await client.listCount(
        model: 'EligibleServices',
        fields: 'id,nameEn',
        filters: const {'executeActionName': 'CitizenEligibleServiceList'},
        page: 1,
        size: 5,
      );

      expect(result.total, 7);
      expect(capturedBody?['model'], 'EligibleServices');
      expect(capturedBody?['fields'], 'id,nameEn');
      expect(capturedBody?['page'], 1);
      expect(capturedBody?['size'], 5);
      expect(
        capturedBody?['filters'],
        {'executeActionName': 'CitizenEligibleServiceList'},
      );
    });

    test('throws on ERROR status in JSON body', () async {
      adapter.onPost(
        '/api/nextquery/EligibleServices/list-count',
        (server) => server.reply(200, {
          'status': 'ERROR',
          'message': 'Invalid field serviceName',
        }),
        data: Matchers.any,
      );

      expect(
        () => client.listCount(
          model: 'EligibleServices',
          fields: 'id',
          filters: const {'executeActionName': 'CitizenEligibleServiceList'},
        ),
        throwsA(
          predicate<ApiException>(
            (e) => e.message.contains('Invalid field serviceName'),
          ),
        ),
      );
    });

    test('list posts to list endpoint', () async {
      adapter.onPost(
        '/api/nextquery/CitizenServiceConsent/list',
        (server) => server.reply(200, {
          'rows': [
            {'id': 10, 'status': 'APPROVED'},
          ],
          'total': 1,
        }),
        data: Matchers.any,
      );

      final result = await client.list(
        model: 'CitizenServiceConsent',
        fields: 'id,status',
      );

      expect(result.total, 1);
      expect(result.rows.first['status'], 'APPROVED');
    });
  });
}
