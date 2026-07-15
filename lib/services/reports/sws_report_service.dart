import 'package:dio/dio.dart';

import '../../models/report_models.dart';
import '../api_exception.dart';
import '../next_query_client.dart';
import '../smart_api_client.dart';

/// Web-style hierarchical report API calls (UAT /department/report).
class SwsReportService {
  SwsReportService._();

  static final SwsReportService instance = SwsReportService._();

  final SmartApiClient _client = SmartApiClient.instance;
  final NextQueryClient _nextQuery = NextQueryClient.instance;

  static final _deptOptions = Options(extra: {'roleHeader': 'DEPARTMENT'});

  Future<List<ServiceOption>> fetchServices() async {
    final result = await _nextQuery.list(
      model: 'ServiceRegistration',
      fields: 'id,serviceId,serviceName',
      filters: {
        'and': [
          {'field': 'serviceCurrentStatus', 'op': '=', 'value': 'ACTIVE'},
        ],
      },
      size: 500,
      roleHeader: 'DEPARTMENT',
    );
    final services = result.rows
        .map(ServiceOption.fromRow)
        .where((s) => s.serviceId.isNotEmpty)
        .toList();

    return [
      const ServiceOption(serviceId: '1000', serviceName: 'All'),
      ...services,
    ];
  }

  Future<List<Map<String, dynamic>>> fetchAllServiceCounts(
    ReportFilterState filters,
  ) =>
      _fetchList(
        'servicestatusreport',
        {
          'startDate': filters.isoStartDate,
          'endDate': filters.isoEndDate,
        },
      );

  Future<List<Map<String, dynamic>>> fetchDistrictCounts(
    ReportFilterState filters,
  ) =>
      _fetchList(
        'districtservicereport',
        {
          'startDate': filters.isoStartDate,
          'endDate': filters.isoEndDate,
          'serviceId': _serviceIdParam(filters.serviceId),
        },
      );

  Future<List<Map<String, dynamic>>> fetchAreaCounts(
    ReportFilterState filters,
  ) =>
      _fetchList(
        'areaservicereport',
        {
          'startDate': filters.isoStartDate,
          'endDate': filters.isoEndDate,
          'serviceId': _serviceIdParam(filters.serviceId),
          'districtId': filters.districtId ?? '0',
          if (filters.districtName != null && filters.districtName!.isNotEmpty)
            'districtName': filters.districtName,
        },
      );

  Future<List<Map<String, dynamic>>> fetchBlockCounts(
    ReportFilterState filters,
  ) =>
      _fetchList(
        'blockservicereport',
        {
          'startDate': filters.isoStartDate,
          'endDate': filters.isoEndDate,
          'serviceId': _serviceIdParam(filters.serviceId),
          'districtId': filters.districtId ?? '0',
          'selectedRural': filters.selectedRural ?? 'Rural',
          if (filters.districtName != null && filters.districtName!.isNotEmpty)
            'districtName': filters.districtName,
        },
      );

  Future<List<Map<String, dynamic>>> fetchBeneficiaries(
    ReportFilterState filters,
  ) =>
      _fetchList(
        'beneficiariservicereport',
        {
          'startDate': filters.isoStartDate,
          'endDate': filters.isoEndDate,
          'serviceId': _serviceIdParam(filters.serviceId),
          // Match web memberList query string fields.
          'districtId': filters.districtId ?? '0',
          'districtName': filters.districtName ?? '',
          'blockName': filters.blockName ?? '',
          'blockId': int.tryParse(filters.blockId ?? '0') ?? 0,
          // Web: Rural → "0", Urban → "1" (string/int both accepted).
          'selectedRural': _selectedRuralParam(filters),
        },
      );

  Future<List<Map<String, dynamic>>> fetchForLevel(ReportFilterState filters) {
    return switch (filters.drillLevel) {
      ReportDrillLevel.allServices => fetchAllServiceCounts(filters),
      ReportDrillLevel.districts => fetchDistrictCounts(filters),
      ReportDrillLevel.ruralUrban => fetchAreaCounts(filters),
      ReportDrillLevel.blocks => fetchBlockCounts(filters),
      ReportDrillLevel.beneficiaries => fetchBeneficiaries(filters),
    };
  }

  static int _serviceIdParam(String serviceId) =>
      int.tryParse(serviceId) ?? 1000;

  /// Match web `memberList`: Rural → 0, Urban → 1 for beneficiariservicereport.
  /// Do not use store selectedRuralId (0=Urban / 1=Rural) for this endpoint.
  static int _selectedRuralParam(ReportFilterState filters) {
    final rural = filters.selectedRural?.trim().toLowerCase() ?? '';
    if (rural == 'rural' || rural.contains('rural') || rural.contains('ग्रामीण')) {
      return 0;
    }
    // Urban (and default when Urban selected) → 1
    return 1;
  }

  /// Exposed for unit tests.
  static int selectedRuralParamForTest(ReportFilterState filters) =>
      _selectedRuralParam(filters);

  Future<List<Map<String, dynamic>>> _fetchList(
    String endpoint,
    Map<String, dynamic> params,
  ) async {
    try {
      final response = await _client.get<dynamic>(
        '/api/services/$endpoint',
        queryParameters: params,
        options: _deptOptions,
      );
      return _parseListResponse(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  static List<Map<String, dynamic>> _parseListResponse(Object? data) {
    if (data == null) return [];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final status = map['status']?.toString().toUpperCase();
      if (status == 'ERROR') {
        throw ApiException(
          message: map['message']?.toString() ?? 'Report request failed.',
        );
      }
      final nested = map['data'];
      if (nested is List) {
        return nested
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
      }
      if (_looksLikeBeneficiaryRow(map)) return [map];
      return [];
    }
    return [];
  }

  static bool _looksLikeBeneficiaryRow(Map<String, dynamic> map) {
    for (final key in map.keys) {
      final upper = key.toUpperCase();
      if (upper == 'MEMBERNAME' ||
          upper == 'MEMBERID' ||
          upper == 'MEMBER_NAME' ||
          upper == 'MEMBER_ID') {
        return true;
      }
    }
    return false;
  }
}
