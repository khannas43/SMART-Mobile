import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/models/user_role.dart';
import 'package:smart_rajasthan/services/api_exception.dart';
import 'package:smart_rajasthan/services/api_interceptors.dart';
import 'package:smart_rajasthan/services/auth_service.dart';
import 'package:smart_rajasthan/services/role/role_context.dart';
import 'package:smart_rajasthan/services/smart_api_client.dart';

import '../helpers/fake_secure_storage.dart';
import '../helpers/jwt_test_utils.dart';

Future<void> waitForSessionCleared() async {
  for (var i = 0; i < 50; i++) {
    if (!AuthService.instance.isAuthenticated) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('AuthService still authenticated after endSession');
}

void main() {
  setUp(() {
    installFakeSecureStorage();
    RoleContext.instance.setActivePanel(SmartPanel.citizen);
  });

  tearDown(() async {
    AuthService.instance.acknowledgeSessionEnded();
    await AuthService.instance.clearToken();
    tearDownFakeSecureStorage();
  });

  group('NetworkRetryInterceptor', () {
    test('retries connection errors then succeeds', () async {
      var attempts = 0;
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.interceptors.add(
        NetworkRetryInterceptor(dio, maxRetries: 2, baseDelay: Duration.zero),
      );
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          attempts++;
          if (attempts < 2) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
              ),
              true,
            );
            return;
          }
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {'ok': true},
            ),
          );
        },
      ));

      final response = await dio.get('/retry');
      expect(response.statusCode, 200);
      expect(attempts, 2);
    });
  });

  group('SmartApiClient auth interceptor', () {
    test('adds Bearer token and active role header', () async {
      await AuthService.instance.saveToken(validCitizenJwt());
      RoleContext.instance.setActivePanel(SmartPanel.citizen);

      final dio = Dio(BaseOptions(baseUrl: 'https://smarttest.example/smart'));
      Map<String, dynamic>? capturedHeaders;

      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedHeaders = Map<String, dynamic>.from(options.headers);
          handler.resolve(
            Response(requestOptions: options, statusCode: 200, data: {}),
          );
        },
      ));

      final client = SmartApiClient.forTest(dio);
      dio.interceptors.insert(0, client.authInterceptor);

      await client.get('/api/sso/getProfile');

      expect(capturedHeaders?['Authorization'], startsWith('Bearer '));
      expect(capturedHeaders?['X-Current-Role'], 'CITIZEN');
    });
  });

  group('GlobalApiErrorInterceptor', () {
    test('ends session on 401 unless skipAuthErrorHandling', () async {
      await AuthService.instance.saveToken(validCitizenJwt());

      final dio = Dio();
      dio.interceptors.add(GlobalApiErrorInterceptor());
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 401,
                data: {'message': 'Unauthorized'},
              ),
              type: DioExceptionType.badResponse,
            ),
            true,
          );
        },
      ));

      await expectLater(
        dio.get('/smart/api/test'),
        throwsA(isA<DioException>()),
      );
      await waitForSessionCleared();
      expect(AuthService.instance.isAuthenticated, isFalse);
      expect(AuthService.instance.sessionEndedMessage, 'Unauthorized');
    });
  });
}
