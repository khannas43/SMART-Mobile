import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';
import 'api_error_presenter.dart';
import 'api_exception.dart';
import 'api_interceptors.dart';
import 'auth_service.dart';
import 'role/role_context.dart';

export 'api_exception.dart';

/// Shared Dio client for SMART backend (`/smart` context path).
class SmartApiClient {
  SmartApiClient._({Dio? dio}) : _dio = dio ?? Dio(_baseOptions) {
    _dio.interceptors.addAll(_buildInterceptors());
  }

  @visibleForTesting
  factory SmartApiClient.forTest(Dio dio) => SmartApiClient._(dio: dio);

  static final SmartApiClient instance = SmartApiClient._();

  static const Duration _defaultTimeout = Duration(seconds: 30);

  static BaseOptions get _baseOptions => BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: _defaultTimeout,
        receiveTimeout: _defaultTimeout,
        sendTimeout: _defaultTimeout,
        headers: const {
          'Accept': 'application/json',
        },
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      );

  final Dio _dio;

  Dio get dio => _dio;

  /// Attaches JWT and SMART role headers (matches web `api-fetcher.ts`).
  late final Interceptor authInterceptor = InterceptorsWrapper(
    onRequest: (options, handler) {
      final auth = AuthService.instance;
      final roleCtx = RoleContext.instance;
      final token = auth.accessToken;
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        final forcedRole = options.extra['roleHeader']?.toString().trim();
        final roleHeader = (forcedRole != null && forcedRole.isNotEmpty)
            ? forcedRole.toUpperCase()
            : roleCtx.currentRoleHeader;
        options.headers['X-Current-Role'] = roleHeader;

        if (roleHeader == 'CITIZEN') {
          options.headers.remove('X-Department-Code');
          options.headers.remove('X-Current-LevelId');
          options.headers.remove('X-Current-Distids');
          options.headers.remove('X-Current-Blockids');
        } else {
          final deptCode = roleCtx.selectedDeptId ?? auth.departmentCode;
          if (deptCode != null && deptCode.isNotEmpty) {
            options.headers['X-Department-Code'] = deptCode;
          } else {
            options.headers.remove('X-Department-Code');
          }
          final levelId = roleCtx.levelIdHeader;
          if (levelId != null && levelId.isNotEmpty) {
            options.headers['X-Current-LevelId'] = levelId;
          } else {
            options.headers.remove('X-Current-LevelId');
          }
          final distIds = roleCtx.districtIdsHeader;
          if (distIds != null && distIds.isNotEmpty) {
            options.headers['X-Current-Distids'] = distIds;
          } else {
            options.headers.remove('X-Current-Distids');
          }
          final blockIds = roleCtx.blockIdsHeader;
          if (blockIds != null && blockIds.isNotEmpty) {
            options.headers['X-Current-Blockids'] = blockIds;
          } else {
            options.headers.remove('X-Current-Blockids');
          }
        }
      } else {
        options.headers.remove('Authorization');
        options.headers.remove('X-Current-Role');
        options.headers.remove('X-Department-Code');
        options.headers.remove('X-Current-LevelId');
        options.headers.remove('X-Current-Distids');
        options.headers.remove('X-Current-Blockids');
      }
      handler.next(options);
    },
  );

  List<Interceptor> _buildInterceptors() {
    return [
      authInterceptor,
      NetworkRetryInterceptor(_dio),
      GlobalApiErrorInterceptor(),
      if (kDebugMode)
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (obj) => debugPrint('[SmartApi] ${_redactLogLine(obj)}'),
        ),
      InterceptorsWrapper(
        onError: (error, handler) {
          final apiError = ApiException.fromDioException(error);
          if (apiError.isForbidden) {
            ApiErrorPresenter.show(apiError);
          }
          handler.reject(
            error.copyWith(error: apiError),
          );
        },
      ),
    ];
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.get<T>(
      _normalizePath(path),
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.post<T>(
      _normalizePath(path),
      data: data,
      queryParameters: queryParameters,
      options: options?.copyWith(
            contentType: options.contentType ?? Headers.jsonContentType,
          ) ??
          Options(contentType: Headers.jsonContentType),
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> postForm<T>(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.post<T>(
      _normalizePath(path),
      data: data,
      queryParameters: queryParameters,
      options: options?.copyWith(
            contentType:
                options.contentType ?? Headers.formUrlEncodedContentType,
          ) ??
          Options(contentType: Headers.formUrlEncodedContentType),
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.put<T>(
      _normalizePath(path),
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      _normalizePath(path),
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  String _normalizePath(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return path.startsWith('/') ? path : '/$path';
  }

  static String _redactLogLine(Object obj) {
    return obj
        .toString()
        .replaceAllMapped(
          RegExp(r'(Authorization:\s*Bearer\s+)\S+', caseSensitive: false),
          (m) => '${m[1]}[REDACTED]',
        )
        .replaceAllMapped(
          RegExp(r'("password"\s*:\s*")[^"]*(")', caseSensitive: false),
          (m) => '${m[1]}[REDACTED]${m[2]}',
        );
  }
}
