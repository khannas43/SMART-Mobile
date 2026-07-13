import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'smart_api_client.dart';
import 'api_exception.dart';

/// Result from `/api/nextquery/{model}/list` or `list-count`.
class NextQueryResult {
  const NextQueryResult({
    required this.rows,
    required this.total,
  });

  final List<Map<String, dynamic>> rows;
  final int total;

  factory NextQueryResult.fromResponse(Object? data) {
    if (data is! Map) {
      return const NextQueryResult(rows: [], total: 0);
    }

    final rowsRaw = data['rows'];
    final rows = <Map<String, dynamic>>[];
    if (rowsRaw is List) {
      for (final row in rowsRaw) {
        if (row is Map<String, dynamic>) {
          rows.add(row);
        } else if (row is Map) {
          rows.add(Map<String, dynamic>.from(row));
        }
      }
    }

    final totalValue = data['total'];
    final total = switch (totalValue) {
      int i => i,
      num n => n.toInt(),
      String s => int.tryParse(s) ?? rows.length,
      _ => rows.length,
    };

    return NextQueryResult(rows: rows, total: total);
  }
}

/// POST wrapper for SMART nextquery APIs (matches web `createNextQueryFetcher`).
class NextQueryClient {
  NextQueryClient._([SmartApiClient? client])
      : _client = client ?? SmartApiClient.instance;

  static final NextQueryClient instance = NextQueryClient._();

  /// Injected API client for unit tests (activity 2.14).
  @visibleForTesting
  factory NextQueryClient.forTest(SmartApiClient client) =>
      NextQueryClient._(client);

  final SmartApiClient _client;

  Future<NextQueryResult> list({
    required String model,
    required String fields,
    dynamic filters,
    int page = 1,
    int size = 10,
    Map<String, dynamic>? sorting,
    String? roleHeader,
  }) {
    return _query(
      model,
      'list',
      fields,
      filters,
      page,
      size,
      sorting,
      roleHeader: roleHeader,
    );
  }

  Future<NextQueryResult> listCount({
    required String model,
    required String fields,
    dynamic filters,
    int page = 1,
    int size = 10,
    Map<String, dynamic>? sorting,
    String? roleHeader,
  }) {
    return _query(
      model,
      'list-count',
      fields,
      filters,
      page,
      size,
      sorting,
      roleHeader: roleHeader,
    );
  }

  Future<Map<String, dynamic>> create({
    required String model,
    required Map<String, dynamic> data,
    String? roleHeader,
  }) async {
    final response = await _client.post(
      '/api/nextquery/$model/create',
      data: {
        'model': model,
        'data': data,
      },
      options: roleHeader == null
          ? null
          : Options(extra: {'roleHeader': roleHeader}),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> update({
    required String model,
    required String idField,
    required String idValue,
    required Map<String, dynamic> data,
    String? roleHeader,
  }) async {
    final response = await _client.post(
      '/api/nextquery/$model/update/$idField/$idValue',
      data: {
        'model': model,
        'data': data,
      },
      options: roleHeader == null
          ? null
          : Options(extra: {'roleHeader': roleHeader}),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> findOne({
    required String model,
    required String idValue,
    String idField = 'id',
    String fields = '*',
  }) async {
    final response = await _client.post(
      '/api/nextquery/$model/findone/$idValue/$idField',
      data: {
        'model': model,
        'fields': fields,
      },
    );
    return _asMap(response.data);
  }

  Future<NextQueryResult> _query(
    String model,
    String action,
    String fields,
    dynamic filters,
    int page,
    int size,
    Map<String, dynamic>? sorting, {
    String? roleHeader,
  }) async {
    final body = <String, dynamic>{
      'model': model,
      'fields': fields,
      'page': page,
      'size': size,
      if (filters != null) 'filters': filters,
      if (sorting != null) 'sorting': sorting,
    };

    try {
      final response = await _client.post(
        '/api/nextquery/$model/$action',
        data: body,
        options: roleHeader == null
            ? null
            : Options(extra: {'roleHeader': roleHeader}),
      );
      return _parseQueryResponse(response.data, model, action);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  NextQueryResult _parseQueryResponse(
    Object? data,
    String model,
    String action,
  ) {
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) {
        throw ApiException(
          message: 'Server returned an empty response. Please try again.',
          path: '/api/nextquery/$model/$action',
        );
      }
      if (trimmed.startsWith('<')) {
        throw ApiException(
          message: 'Server returned an unexpected response. Please try again.',
          path: '/api/nextquery/$model/$action',
        );
      }
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final status = map['status']?.toString().toUpperCase();
      if (status == 'ERROR' || status == 'FAILED') {
        throw ApiException(
          message: map['message']?.toString() ??
              'Request failed. Please try again.',
          path: '/api/nextquery/$model/$action',
        );
      }
    }

    return NextQueryResult.fromResponse(data);
  }

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }
}
