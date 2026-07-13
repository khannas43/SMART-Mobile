import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:smart_rajasthan/config/sso_config.dart';
import 'package:smart_rajasthan/services/auth_service.dart';
import 'package:smart_rajasthan/services/smart_api_client.dart';
import 'package:smart_rajasthan/services/sso_landing_service.dart';

import '../helpers/fake_secure_storage.dart';
import '../helpers/jwt_test_utils.dart';

void main() {
  setUp(() {
    installFakeSecureStorage();
  });

  tearDown(() async {
    await AuthService.instance.clearToken();
    tearDownFakeSecureStorage();
  });

  group('SsoLandingService.jwtFromSetCookieHeaders', () {
    test('extracts jwt cookie value', () {
      final headers = Headers.fromMap({
        'set-cookie': [
          'jwt=abc.def.ghi; Path=/; HttpOnly',
        ],
      });
      expect(
        SsoLandingService.jwtFromSetCookieHeaders(headers),
        'abc.def.ghi',
      );
    });

    test('extracts jwt from Spring ResponseCookie format (activity 3.7a)', () {
      final headers = Headers.fromMap({
        'set-cookie': [
          'jwt=eyJ.header.sig; Path=/; Max-Age=900; Expires=Wed, 01 Jan 2025 00:00:00 GMT; Secure; HttpOnly; SameSite=Lax',
        ],
      });
      expect(
        SsoLandingService.jwtFromSetCookieHeaders(headers),
        'eyJ.header.sig',
      );
    });

    test('skips non-jwt cookies and reads jwt from second Set-Cookie', () {
      final headers = Headers.fromMap({
        'set-cookie': [
          'JSESSIONID=abc123; Path=/; HttpOnly',
          'jwt=token.from.cookie; Path=/',
        ],
      });
      expect(
        SsoLandingService.jwtFromSetCookieHeaders(headers),
        'token.from.cookie',
      );
    });
  });

  group('SsoLandingService.exchangeUserdetails', () {
    late Dio dio;
    late DioAdapter adapter;
    late SsoLandingService service;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://smarttest.example/smart'));
      adapter = DioAdapter(dio: dio);
      dio.httpClientAdapter = adapter;
      service = SsoLandingService.forTest(SmartApiClient.forTest(dio));
    });

    test('uses JSON token from mobile-landing when available', () async {
      final token = validCitizenJwt();

      adapter.onPost(
        SsoConfig.mobileLandingPath,
        (server) => server.reply(200, {
          'token': token,
          'currentSrole': 'citizen',
        }),
        queryParameters: {'userdetails': 'enc-user'},
      );

      final result = await service.exchangeUserdetails(userdetails: 'enc-user');
      expect(result.token, token);
      expect(result.currentSrole, 'citizen');
    });

    test('falls back to sandboxlanding Set-Cookie when mobile-landing is 404', () async {
      final token = validCitizenJwt();

      adapter.onPost(
        SsoConfig.mobileLandingPath,
        (server) => server.reply(404, {'message': 'not found'}),
        queryParameters: {'userdetails': 'enc-user'},
      );

      adapter.onPost(
        SsoConfig.sandboxLandingPath,
        (server) => server.reply(200, {
          'status': 'success',
          'redirectUrl': 'http://localhost:3000/citizen',
        }, headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
          'set-cookie': ['jwt=$token; Path=/; HttpOnly'],
        }),
        queryParameters: {'userdetails': 'enc-user', 'ssoId': ''},
      );

      final result = await service.exchangeUserdetails(userdetails: 'enc-user');
      expect(result.token, token);
      expect(result.redirectPath, 'http://localhost:3000/citizen');
    });

    test('passes ssoId to sandboxlanding when callback includes it', () async {
      final token = validCitizenJwt();

      adapter.onPost(
        SsoConfig.mobileLandingPath,
        (server) => server.reply(404, {}),
        queryParameters: {'userdetails': 'enc-user'},
      );

      adapter.onPost(
        SsoConfig.sandboxLandingPath,
        (server) => server.reply(200, {'status': 'success'}, headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
          'set-cookie': ['jwt=$token; Path=/'],
        }),
        queryParameters: {
          'userdetails': 'enc-user',
          'ssoId': 'GOURAV99GOYAL',
        },
      );

      final result = await service.exchangeUserdetails(
        userdetails: 'enc-user',
        ssoId: 'GOURAV99GOYAL',
      );
      expect(result.token, token);
    });

    test('mobile-rest fallback uses sandboxlanding with ssoId on all environments', () async {
      final token = validCitizenJwt();

      adapter.onPost(
        SsoConfig.sandboxLandingPath,
        (server) => server.reply(200, {'status': 'success'}, headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
          'set-cookie': ['jwt=$token; Path=/'],
        }),
        queryParameters: {
          'userdetails': 'mobile-rest:GOURAV99GOYAL',
          'ssoId': 'GOURAV99GOYAL',
        },
      );

      final result = await service.exchangeUserdetails(
        userdetails: 'mobile-rest:GOURAV99GOYAL',
        ssoId: 'GOURAV99GOYAL',
      );
      expect(result.token, token);
    });

    test('completeLogin persists JWT in AuthService', () async {
      final token = validCitizenJwt();

      adapter.onPost(
        SsoConfig.mobileLandingPath,
        (server) => server.reply(404, {}),
        queryParameters: {'userdetails': 'enc-user'},
      );

      adapter.onPost(
        SsoConfig.sandboxLandingPath,
        (server) => server.reply(200, {'status': 'success'}, headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
          'set-cookie': ['jwt=$token; Path=/'],
        }),
        queryParameters: {'userdetails': 'enc-user', 'ssoId': ''},
      );

      await service.completeLogin(userdetails: 'enc-user');
      expect(AuthService.instance.isAuthenticated, isTrue);
      expect(AuthService.instance.accessToken, token);
    });
  });
}
