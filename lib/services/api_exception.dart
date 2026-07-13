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
class ApiException implements Exception {
  ApiException({
    required this.message,
    this.kind = ApiErrorKind.unknown,
    this.statusCode,
    this.path,
    this.cause,
  });

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
    return 'ApiException$code$at: $message';
  }

  factory ApiException.fromDioException(DioException error) {
    final nested = error.error;
    if (nested is ApiException) return nested;

    final root = nested ?? error;
    if (root is SocketException) {
      return ApiException(
        message: 'Unable to reach SMART servers. Check your internet connection.',
        kind: ApiErrorKind.network,
        path: error.requestOptions.uri.path,
        cause: error,
      );
    }
    if (root is HandshakeException) {
      return ApiException(
        message: 'Secure connection failed. Check network or try again later.',
        kind: ApiErrorKind.network,
        path: error.requestOptions.uri.path,
        cause: error,
      );
    }
    if (root is FormatException) {
      return ApiException(
        message: 'Server returned an unexpected response. Please try again.',
        kind: ApiErrorKind.server,
        path: error.requestOptions.uri.path,
        cause: error,
      );
    }

    final response = error.response;
    final statusCode = response?.statusCode;
    final path = error.requestOptions.uri.path;
    final serverMessage = extractServerMessage(response?.data);

    if (statusCode == 401) {
      return ApiException(
        message: serverMessage ??
            'Your session has expired. Please sign in again.',
        kind: ApiErrorKind.unauthorized,
        statusCode: statusCode,
        path: path,
        cause: error,
      );
    }

    if (statusCode == 403) {
      return ApiException(
        message: _forbiddenMessage(serverMessage),
        kind: ApiErrorKind.forbidden,
        statusCode: statusCode,
        path: path,
        cause: error,
      );
    }

    final kind = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout ||
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
      DioExceptionType.transformTimeout =>
        'Request timed out. Check your network and try again.',
      DioExceptionType.connectionError =>
        'Unable to reach SMART servers. Check your internet connection.',
      DioExceptionType.badCertificate => 'Secure connection failed.',
      DioExceptionType.cancel => 'Request was cancelled.',
      DioExceptionType.badResponse =>
        serverMessage ?? 'Server returned HTTP $statusCode.',
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
    if (statusCode >= 400) return ApiErrorKind.client;
    return ApiErrorKind.unknown;
  }

  static String _messageFromUnknown(DioException error, String? serverMessage) {
    if (serverMessage != null && serverMessage.trim().isNotEmpty) {
      return serverMessage.trim();
    }
    final nested = error.error;
    if (nested is Exception && nested.toString().trim().isNotEmpty) {
      final text = nested.toString();
      if (text.contains('SocketException') || text.contains('Failed host lookup')) {
        return 'Unable to reach SMART servers. Check your internet connection.';
      }
      if (text.contains('HandshakeException') || text.contains('CERT')) {
        return 'Secure connection failed. Check network or try again later.';
      }
    }
    final message = error.message?.trim();
    if (message != null && message.isNotEmpty) return message;
    return 'Unexpected network error. Please try again.';
  }

  static String _forbiddenMessage(String? serverMessage) {
    if (serverMessage == null || serverMessage.trim().isEmpty) {
      return 'You do not have permission to perform this action.';
    }
    final lower = serverMessage.toLowerCase();
    if (lower.contains('access denied') ||
        lower.contains('permission') ||
        lower.contains('forbidden') ||
        lower.contains('acl')) {
      return serverMessage.trim();
    }
    return 'Access denied: ${serverMessage.trim()}';
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
