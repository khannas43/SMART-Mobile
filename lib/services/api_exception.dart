import 'dart:io';

import 'package:dio/dio.dart';

/// Category of API failure for UI routing and retry logic.
enum ApiErrorKind {
  network,
  unauthorized,
  forbidden,
  client,
  server,
  cancelled,
  unknown,
}

/// Thrown when an HTTP call fails or returns an unexpected payload.
///
/// [message] is always UI-safe. Debug details stay in [toString], [path],
/// [statusCode], and [cause].
class ApiException implements Exception {
  ApiException({
    required this.message,
    this.kind = ApiErrorKind.unknown,
    this.statusCode,
    this.path,
    this.cause,
  });

  static const sessionExpiredMessage =
      'Session Expired / Please Login Again';
  static const unauthorizedResourceMessage =
      'You are not authorized to access this resource.';
  static const invalidRequestMessage = 'Invalid Request';
  static const notFoundMessage = 'Requested data not found.';
  static const serverErrorMessage =
      'Internal Server Error. Please try again later.';
  static const networkErrorMessage =
      'Unable to connect to the server. Please check your internet connection.';

  final String message;
  final ApiErrorKind kind;
  final int? statusCode;
  final String? path;
  final Object? cause;

  bool get isUnauthorized => kind == ApiErrorKind.unauthorized;
  bool get isForbidden => kind == ApiErrorKind.forbidden;
  bool get isNetworkError => kind == ApiErrorKind.network;
  bool get isRetryable => kind == ApiErrorKind.network;

  @override
  String toString() {
    final code = statusCode != null ? ' (HTTP $statusCode)' : '';
    final at = path != null ? ' [$path]' : '';
    final detail = cause != null ? ' cause=$cause' : '';
    return 'ApiException$code$at: $message$detail';
  }

  factory ApiException.fromDioException(DioException error) {
    final nested = error.error;
    if (nested is ApiException) return nested;

    final path = error.requestOptions.uri.path;
    final response = error.response;
    final statusCode = response?.statusCode;
    final serverMessage = extractServerMessage(response?.data);

    final root = nested ?? error;
    if (root is SocketException) {
      return ApiException(
        message: networkErrorMessage,
        kind: ApiErrorKind.network,
        path: path,
        cause: error,
      );
    }
    if (root is HandshakeException) {
      return ApiException(
        message: networkErrorMessage,
        kind: ApiErrorKind.network,
        path: path,
        cause: error,
      );
    }
    if (root is FormatException) {
      return ApiException(
        message: serverErrorMessage,
        kind: ApiErrorKind.server,
        path: path,
        cause: error,
      );
    }

    if (statusCode == 401) {
      return ApiException(
        message: sessionExpiredMessage,
        kind: ApiErrorKind.unauthorized,
        statusCode: statusCode,
        path: path,
        cause: error,
      );
    }

    if (statusCode == 403) {
      return ApiException(
        message: unauthorizedResourceMessage,
        kind: ApiErrorKind.forbidden,
        statusCode: statusCode,
        path: path,
        cause: error,
      );
    }

    if (statusCode == 400) {
      return ApiException(
        message: invalidRequestMessage,
        kind: ApiErrorKind.client,
        statusCode: statusCode,
        path: path,
        cause: error,
      );
    }

    if (statusCode == 404) {
      return ApiException(
        message: notFoundMessage,
        kind: ApiErrorKind.client,
        statusCode: statusCode,
        path: path,
        cause: error,
      );
    }

    if (statusCode != null && statusCode >= 500) {
      return ApiException(
        message: serverErrorMessage,
        kind: ApiErrorKind.server,
        statusCode: statusCode,
        path: path,
        cause: error,
      );
    }

    final kind = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        ApiErrorKind.network,
      DioExceptionType.cancel => ApiErrorKind.cancelled,
      DioExceptionType.badCertificate => ApiErrorKind.network,
      DioExceptionType.badResponse => _kindFromStatus(statusCode),
      DioExceptionType.unknown => ApiErrorKind.unknown,
    };

    final message = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError ||
      DioExceptionType.badCertificate =>
        networkErrorMessage,
      DioExceptionType.cancel => 'Request was cancelled.',
      DioExceptionType.badResponse =>
        _friendlyFromStatus(statusCode, serverMessage),
      DioExceptionType.unknown =>
        _messageFromUnknown(error, serverMessage),
    };

    return ApiException(
      message: message,
      kind: kind,
      statusCode: statusCode,
      path: path,
      cause: error,
    );
  }

  static ApiErrorKind _kindFromStatus(int? statusCode) {
    if (statusCode == null) return ApiErrorKind.unknown;
    if (statusCode >= 500) return ApiErrorKind.server;
    if (statusCode == 403) return ApiErrorKind.forbidden;
    if (statusCode == 401) return ApiErrorKind.unauthorized;
    if (statusCode >= 400) return ApiErrorKind.client;
    return ApiErrorKind.unknown;
  }

  static String _friendlyFromStatus(int? statusCode, String? serverMessage) {
    if (statusCode == 400) return invalidRequestMessage;
    if (statusCode == 401) return sessionExpiredMessage;
    if (statusCode == 403) return unauthorizedResourceMessage;
    if (statusCode == 404) return notFoundMessage;
    if (statusCode != null && statusCode >= 500) return serverErrorMessage;
    if (statusCode != null && statusCode >= 400) return invalidRequestMessage;
    // Avoid raw server strings like "Forbidden" in the UI.
    if (serverMessage != null &&
        serverMessage.toLowerCase().contains('forbidden')) {
      return unauthorizedResourceMessage;
    }
    return serverErrorMessage;
  }

  static String _messageFromUnknown(DioException error, String? serverMessage) {
    final nested = error.error;
    if (nested is Exception && nested.toString().trim().isNotEmpty) {
      final text = nested.toString();
      if (text.contains('SocketException') ||
          text.contains('Failed host lookup') ||
          text.contains('HandshakeException') ||
          text.contains('CERT')) {
        return networkErrorMessage;
      }
    }
    if (serverMessage != null &&
        serverMessage.toLowerCase().contains('forbidden')) {
      return unauthorizedResourceMessage;
    }
    return networkErrorMessage;
  }

  static String? extractServerMessage(Object? data) {
    if (data == null) return null;
    if (data is String && data.trim().isNotEmpty) return data.trim();
    if (data is Map) {
      for (final key in ['message', 'error', 'detail', 'errorMessage']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      final nested = data['data'];
      if (nested is Map) {
        return extractServerMessage(nested);
      }
    }
    return null;
  }
}
