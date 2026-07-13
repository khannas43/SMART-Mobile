import 'dart:io';

import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Normalizes thrown values from Dio / interceptors into [ApiException].
class ApiErrorUtil {
  ApiErrorUtil._();

  static ApiException asApiException(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) return ApiException.fromDioException(error);
    if (error is StateError) {
      return ApiException(message: error.message);
    }
    return ApiException(message: error.toString());
  }

  static String friendlyMessage(Object error) => asApiException(error).message;

  static bool isNetworkRelated(Object error) {
    final api = asApiException(error);
    if (api.isNetworkError) return true;
    final root = _rootCause(error);
    return root is SocketException || root is HandshakeException;
  }

  static Object? _rootCause(Object error) {
    if (error is DioException) return error.error ?? error;
    return error;
  }
}
