import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/services/api_exception.dart';

void main() {
  group('ApiException.fromDioException', () {
    test('maps 401 to unauthorized', () {
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
      expect(apiError.message, 'Token expired');
      expect(apiError.isUnauthorized, isTrue);
    });

    test('maps 403 ACL errors to forbidden with server message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/smart/api/nextquery/EligibleServices/list-count'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 403,
          data: {'message': 'Access Denied: Invalid role'},
        ),
        type: DioExceptionType.badResponse,
      );

      final apiError = ApiException.fromDioException(error);
      expect(apiError.kind, ApiErrorKind.forbidden);
      expect(apiError.isForbidden, isTrue);
      expect(apiError.message, contains('Access Denied'));
    });

    test('maps connection timeout to network kind', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/smart/api/test'),
        type: DioExceptionType.connectionTimeout,
      );

      final apiError = ApiException.fromDioException(error);
      expect(apiError.kind, ApiErrorKind.network);
      expect(apiError.isNetworkError, isTrue);
      expect(apiError.isRetryable, isTrue);
      expect(apiError.message, contains('timed out'));
    });

    test('unwraps nested ApiException from DioException.error', () {
      final nested = ApiException(
        message: 'Access Denied: Invalid role',
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
      expect(apiError.message, 'Access Denied: Invalid role');
      expect(apiError.isForbidden, isTrue);
    });
  });
}
