import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/services/api_error_util.dart';
import 'package:smart_rajasthan/services/api_exception.dart';

void main() {
  test('ApiErrorUtil unwraps DioException with nested ApiException', () {
    final nested = ApiException(message: 'Unable to reach SMART servers.');
    final error = DioException(
      requestOptions: RequestOptions(path: '/smart/api/test'),
      type: DioExceptionType.unknown,
      error: nested,
    );

    expect(
      ApiErrorUtil.friendlyMessage(error),
      'Unable to reach SMART servers.',
    );
  });
}
