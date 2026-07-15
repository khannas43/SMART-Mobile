import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/services/api_exception.dart';

void main() {
  group('ApiException.fromDioException', () {
    test('maps 401 to session expired message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/smart/api/sso/getProfile'),
        response: Response(
          requestOptions: RequestOptions(path: '/smart/api/sso/getProfile'),
          statusCode: 401,
          data: {'message': 'Token expired'},
        ),
        type: DioExceptionType.badResponse,
      );

      final apiError = ApiException.fromDioException(error);
      expect(apiError.kind, ApiErrorKind.unauthorized);
      expect(apiError.statusCode, 401);
      expect(apiError.message, ApiException.sessionExpiredMessage);
      expect(apiError.isUnauthorized, isTrue);
    });

    test('maps 403 Forbidden to friendly unauthorized message', () {
      final error = DioException(
        requestOptions: RequestOptions(
          path: '/smart/api/nextquery/EligibleServices/list-count',
        ),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 403,
          data: 'Forbidden',
        ),
        type: DioExceptionType.badResponse,
      );

      final apiError = ApiException.fromDioException(error);
      expect(apiError.kind, ApiErrorKind.forbidden);
      expect(apiError.isForbidden, isTrue);
      expect(apiError.message, ApiException.unauthorizedResourceMessage);
      expect(apiError.message, isNot(contains('Forbidden')));
    });

    test('maps 400 to Invalid Request', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/smart/api/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/smart/api/test'),
          statusCode: 400,
          data: {'message': 'bad payload'},
        ),
        type: DioExceptionType.badResponse,
      );

      final apiError = ApiException.fromDioException(error);
      expect(apiError.kind, ApiErrorKind.client);
      expect(apiError.message, ApiException.invalidRequestMessage);
    });

    test('maps 404 to Requested data not found', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/smart/api/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/smart/api/test'),
          statusCode: 404,
          data: {'message': 'missing'},
        ),
        type: DioExceptionType.badResponse,
      );

      final apiError = ApiException.fromDioException(error);
      expect(apiError.message, ApiException.notFoundMessage);
    });

    test('maps 500 to friendly server unavailable message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/smart/api/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/smart/api/test'),
          statusCode: 500,
          data: {'message': 'boom'},
        ),
        type: DioExceptionType.badResponse,
      );

      final apiError = ApiException.fromDioException(error);
      expect(apiError.kind, ApiErrorKind.server);
      expect(apiError.message, ApiException.serverErrorMessage);
    });

    test('maps connection timeout to network friendly message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/smart/api/test'),
        type: DioExceptionType.connectionTimeout,
      );

      final apiError = ApiException.fromDioException(error);
      expect(apiError.kind, ApiErrorKind.network);
      expect(apiError.isNetworkError, isTrue);
      expect(apiError.isRetryable, isTrue);
      expect(apiError.message, ApiException.networkErrorMessage);
    });

    test('unwraps nested ApiException from DioException.error', () {
      final nested = ApiException(
        message: ApiException.unauthorizedResourceMessage,
        kind: ApiErrorKind.forbidden,
        statusCode: 403,
      );
      final error = DioException(
        requestOptions: RequestOptions(
          path: '/smart/api/nextquery/EligibleServices/list-count',
        ),
        type: DioExceptionType.unknown,
        error: nested,
      );

      final apiError = ApiException.fromDioException(error);
      expect(apiError.message, ApiException.unauthorizedResourceMessage);
      expect(apiError.isForbidden, isTrue);
    });
  });
}
