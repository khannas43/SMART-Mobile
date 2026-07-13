import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:smart_rajasthan/models/auth_session.dart';
import 'package:smart_rajasthan/services/api_exception.dart';
import 'package:smart_rajasthan/services/consent_otp_service.dart';
import 'package:smart_rajasthan/services/smart_api_client.dart';

void main() {
  group('ConsentOtpService.parseSendResponse', () {
    test('parses nested SUCCESS payload', () {
      final result = ConsentOtpService.parseSendResponse({
        'data': {
          'transactionId': 'txn-123',
          'otpPrefix': 'ABCD',
          'mobile': '*****8592',
          'status': 'SUCCESS',
        },
      });

      expect(result.transactionId, 'txn-123');
      expect(result.otpPrefix, 'ABCD');
      expect(result.maskedMobile, '*****8592');
    });

    test('throws on FAILED status even when HTTP would be 200', () {
      expect(
        () => ConsentOtpService.parseSendResponse({
          'data': {
            'status': 'FAILED',
            'message': 'Mobile number not found for id: 10',
            'statusCode': 400,
          },
        }),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Mobile number not found for id: 10',
          ),
        ),
      );
    });

    test('throws when transactionId missing', () {
      expect(
        () => ConsentOtpService.parseSendResponse({
          'data': {'status': 'SUCCESS', 'message': 'No txn'},
        }),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('ConsentOtpService.parseValidateResponse', () {
    test('accepts status true', () {
      final result = ConsentOtpService.parseValidateResponse({
        'status': true,
        'message': 'OTP has been successfully validated',
      });

      expect(result.valid, isTrue);
      expect(result.message, contains('successfully validated'));
    });

    test('accepts isvalidate true', () {
      final result = ConsentOtpService.parseValidateResponse({
        'isvalidate': true,
        'message': 'OK',
      });

      expect(result.valid, isTrue);
    });

    test('accepts status SUCCESS string', () {
      final result = ConsentOtpService.parseValidateResponse({
        'data': {
          'status': 'SUCCESS',
          'message': 'OTP has been successfully validated',
        },
      });

      expect(result.valid, isTrue);
    });

    test('throws when otpPrefix missing on validateOtp', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://smarttest.example/smart'));
      final adapter = DioAdapter(dio: dio);
      dio.httpClientAdapter = adapter;
      final service = ConsentOtpService.forTest(SmartApiClient.forTest(dio));

      await expectLater(
        service.validateOtp(tid: 'txn-1', otp: '123456'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('OTP session incomplete'),
          ),
        ),
      );
    });

    test('throws friendly message when validation fails', () {
      expect(
        () => ConsentOtpService.parseValidateResponse({
          'status': false,
          'message': 'OTP validation failed. Please try again.',
        }),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'OTP validation failed. Please try again.',
          ),
        ),
      );
    });
  });

  group('ConsentOtpService.consentProfileBlockReason', () {
    test('blocks when smUserId or jfId missing', () async {
      expect(
        await ConsentOtpService.consentProfileBlockReason(
          session: const AuthSession(token: 't', payload: {}),
        ),
        isNotNull,
      );
      expect(
        await ConsentOtpService.consentProfileBlockReason(
          session: const AuthSession(token: 't', payload: {'smUserId': '1'}),
        ),
        isNotNull,
      );
    });

    test('allows when smUserId and jfId present', () async {
      expect(
        await ConsentOtpService.consentProfileBlockReason(
          session: const AuthSession(
            token: 't',
            payload: {'smUserId': '123', 'jfId': '456'},
          ),
        ),
        isNull,
      );
    });
  });

  group('ConsentOtpService HTTP', () {
    late Dio dio;
    late DioAdapter adapter;
    late ConsentOtpService service;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://smarttest.example/smart'));
      adapter = DioAdapter(dio: dio);
      dio.httpClientAdapter = adapter;
      service = ConsentOtpService.forTest(SmartApiClient.forTest(dio));
    });

    test('validateOtp maps HTTP 400 body to ApiException', () async {
      adapter.onGet(
        '/api/CitizenConsent/validateConsentOTP',
        (server) => server.reply(
          400,
          {
            'status': false,
            'message': 'Please update your Jan Aadhaar and Member ID in your SSO profile',
          },
        ),
      );

      await expectLater(
        service.validateOtp(tid: 'txn-1', otp: '123456', otpPrefix: 'ABCD'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Jan Aadhaar'),
          ),
        ),
      );
    });

    test('validateOtp sends transactionId and otpPrefix query params', () async {
      Map<String, dynamic>? capturedQuery;

      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedQuery = Map<String, dynamic>.from(options.queryParameters);
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {'status': true, 'isvalidate': true},
            ),
          );
        },
      ));

      await service.validateOtp(
        tid: 'txn-abc',
        otp: '654321',
        otpPrefix: 'WXYZ',
      );

      expect(capturedQuery?['tid'], 'txn-abc');
      expect(capturedQuery?['transactionId'], 'txn-abc');
      expect(capturedQuery?['otp'], '654321');
      expect(capturedQuery?['otpPrefix'], 'WXYZ');
    });
  });

  group('ApiException.extractServerMessage', () {
    test('reads nested data.message', () {
      expect(
        ApiException.extractServerMessage({
          'data': {
            'status': 'FAILED',
            'message': 'Mobile number not found for id: 10',
          },
        }),
        'Mobile number not found for id: 10',
      );
    });
  });
}
