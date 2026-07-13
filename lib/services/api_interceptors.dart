import 'dart:async';

import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'auth_service.dart';

/// Retries transient network failures (timeouts / connection errors).
class NetworkRetryInterceptor extends Interceptor {
  NetworkRetryInterceptor(
    this._dio, {
    this.maxRetries = 2,
    this.baseDelay = const Duration(milliseconds: 400),
  });

  final Dio _dio;
  final int maxRetries;
  final Duration baseDelay;

  static const _attemptKey = 'smart_retry_attempt';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRetry(err)) {
      return handler.next(err);
    }

    final options = err.requestOptions;
    final attempt = (options.extra[_attemptKey] as int?) ?? 0;
    if (attempt >= maxRetries) {
      return handler.next(err);
    }

    options.extra[_attemptKey] = attempt + 1;
    await Future<void>.delayed(baseDelay * (attempt + 1));

    try {
      final response = await _dio.fetch<Object?>(options);
      handler.resolve(response);
    } on DioException catch (retryErr) {
      handler.next(retryErr);
    }
  }

  bool _shouldRetry(DioException err) {
    if (err.requestOptions.extra['noRetry'] == true) return false;
    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        true,
      _ => false,
    };
  }
}

/// Handles auth/session errors before they are wrapped as [ApiException].
///
/// HTTP 401 ends the session; [SessionGuard] navigates to login (activities 2.11, 3.10).
class GlobalApiErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final skip = err.requestOptions.extra['skipAuthErrorHandling'] == true;
    final statusCode = err.response?.statusCode;

    if (!skip && statusCode == 401) {
      final message = ApiException.extractServerMessage(err.response?.data) ??
          'Your session has expired. Please sign in again.';
      unawaited(AuthService.instance.endSession(message: message));
    }

    handler.next(err);
  }
}
