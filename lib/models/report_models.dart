/// Sws101 report types (matches smart_frontend Sws101ReportsPage).

import 'package:flutter/widgets.dart';

import '../i18n/app_locale.dart';

enum SwsReportType {
  service,
  dayWise,
  district,
  area,
  block,
  beneficiary;

  String get endpoint => switch (this) {
        SwsReportType.service => 'servicestatusreport',
        SwsReportType.dayWise => 'daywiseservicestatusreport',
        SwsReportType.district => 'districtservicereport',
        SwsReportType.area => 'areaservicereport',
        SwsReportType.block => 'blockservicereport',
        SwsReportType.beneficiary => 'beneficiariservicereport',
      };

  String labelEn() => switch (this) {
        SwsReportType.service => 'Service Summary',
        SwsReportType.dayWise => 'Day Wise',
        SwsReportType.district => 'District',
        SwsReportType.area => 'Area',
        SwsReportType.block => 'Block',
        SwsReportType.beneficiary => 'Beneficiary',
      };

  String labelHi() => switch (this) {
        SwsReportType.service => 'सेवा सारांश',
        SwsReportType.dayWise => 'दैनिक',
        SwsReportType.district => 'जिला',
        SwsReportType.area => 'क्षेत्र',
        SwsReportType.block => 'ब्लॉक',
        SwsReportType.beneficiary => 'लाभार्थी',
      };

  bool get requiresService => this != SwsReportType.service && this != SwsReportType.dayWise;

  bool get requiresDistrict =>
      this == SwsReportType.area ||
      this == SwsReportType.block ||
      this == SwsReportType.beneficiary;

  bool get requiresBlock => this == SwsReportType.beneficiary;
}

class ServiceOption {
  const ServiceOption({
    required this.serviceId,
    required this.serviceName,
    this.serviceNameHi = '',
  });

  final String serviceId;
  final String serviceName;
  final String serviceNameHi;

  String localizedName(BuildContext context) =>
      context.lb(serviceName, serviceNameHi);

  factory ServiceOption.fromRow(Map<String, dynamic> row) {
    final id = pickReportField(row, const ['serviceId', 'SERVICE_ID', 'id', 'ID']);
    final name = pickReportField(row, const [
      'serviceName',
      'SERVICE_NAME',
      'nameEn',
      'NAME_EN',
    ]);
    final nameHi = pickReportField(row, const [
      'serviceNameHi',
      'SERVICE_NAME_HI',
      'nameHi',
      'NAME_HI',
    ]);
    return ServiceOption(
      serviceId: id,
      serviceName: name.isNotEmpty ? name : 'Service $id',
      serviceNameHi: nameHi,
    );
  }
}

/// First non-empty value for [keys] (case-insensitive key match).
String pickReportField(Map<String, dynamic> row, List<String> keys) {
  for (final key in keys) {
    for (final entry in row.entries) {
      if (entry.key.toUpperCase() == key.toUpperCase()) {
        final text = entry.value?.toString().trim();
        if (text != null && text.isNotEmpty) return text;
      }
    }
  }
  return '';
}

const _serviceNameEnKeys = ['serviceName', 'SERVICE_NAME'];
const _serviceNameHiKeys = ['serviceNameHi', 'SERVICE_NAME_HI'];
const _districtNameEnKeys = [
  'district_name_en',
  'districtName',
  'DISTRICT_NAME_EN',
  'DISTRICT_NAME',
];
const _districtNameHiKeys = [
  'district_name_hi',
  'districtNameHi',
  'DISTRICT_NAME_HI',
];
const _blockNameEnKeys = [
  'block_name_en',
  'blockName',
  'BLOCK_NAME_EN',
];
const _blockNameHiKeys = [
  'block_name_hi',
  'blockNameHi',
  'BLOCK_NAME_HI',
];

String serviceNameEnFromRow(Map<String, dynamic> row) =>
    pickReportField(row, _serviceNameEnKeys);

String serviceNameHiFromRow(Map<String, dynamic> row) =>
    pickReportField(row, _serviceNameHiKeys);

String districtNameEnFromRow(Map<String, dynamic> row) =>
    pickReportField(row, _districtNameEnKeys);

String districtNameHiFromRow(Map<String, dynamic> row) =>
    pickReportField(row, _districtNameHiKeys);

String blockNameEnFromRow(Map<String, dynamic> row) =>
    pickReportField(row, _blockNameEnKeys);

String blockNameHiFromRow(Map<String, dynamic> row) =>
    pickReportField(row, _blockNameHiKeys);

/// Locale-aware service title from a report SP row.
String localizedServiceTitleFromRow(
  BuildContext context,
  Map<String, dynamic> row,
) =>
    context.lb(serviceNameEnFromRow(row), serviceNameHiFromRow(row));

/// Locale-aware district title from a report SP row.
String localizedDistrictTitleFromRow(
  BuildContext context,
  Map<String, dynamic> row,
) =>
    context.lb(districtNameEnFromRow(row), districtNameHiFromRow(row));

/// Locale-aware block title from a report SP row.
String localizedBlockTitleFromRow(
  BuildContext context,
  Map<String, dynamic> row,
) =>
    context.lb(blockNameEnFromRow(row), blockNameHiFromRow(row));

/// Locale-aware Rural/Urban label. Keeps API values as English; display only.
String localizedAreaLabel(BuildContext context, String? raw) {
  if (isUrbanAreaValue(raw)) return context.l('Urban', 'शहरी');
  if (isRuralAreaValue(raw)) return context.l('Rural', 'ग्रामीण');
  final text = (raw ?? '').trim();
  return text.isEmpty ? '—' : text;
}

/// Raw area field from report row (never the localized display label).
String areaRawFromRow(Map<String, dynamic> row) => pickReportField(row, const [
      'areaName',
      'AREA_NAME',
      'isRural',
      'IS_RURAL',
    ]);

/// True when [raw] represents Urban (existing report conditions).
bool isUrbanAreaValue(String? raw) {
  final normalized = (raw ?? '').trim().toLowerCase();
  if (normalized.isEmpty || normalized == '—') return false;
  // IS_RURAL flag occasionally surfaces as 0/1 or Y/N from area report.
  if (normalized == '0' ||
      normalized == 'n' ||
      normalized == 'no' ||
      normalized == 'false') {
    return true;
  }
  if (normalized == '1' ||
      normalized == 'y' ||
      normalized == 'yes' ||
      normalized == 'true') {
    return false;
  }
  return normalized == 'urban' ||
      normalized.contains('urban') ||
      normalized.contains('शहरी');
}

/// True when [raw] represents Rural (existing report conditions).
bool isRuralAreaValue(String? raw) {
  final normalized = (raw ?? '').trim().toLowerCase();
  if (normalized.isEmpty || normalized == '—') return false;
  if (isUrbanAreaValue(raw)) return false;
  return normalized == 'rural' ||
      normalized.contains('rural') ||
      normalized.contains('ग्रामीण') ||
      normalized == '1' ||
      normalized == 'y' ||
      normalized == 'yes' ||
      normalized == 'true';
}

/// Resolves a locale-aware service label from the catalog by [serviceId].
String localizedServiceLabel(
  BuildContext context, {
  required String? serviceId,
  required String fallbackEn,
  String? fallbackHi,
  required Map<String, ServiceOption> byId,
}) {
  final opt = (serviceId != null && serviceId.isNotEmpty) ? byId[serviceId] : null;
  return context.lb(
    opt?.serviceName ?? fallbackEn,
    opt?.serviceNameHi ?? fallbackHi ?? '',
  );
}

class ReportFilterState {
  const ReportFilterState({
    required this.startDate,
    required this.endDate,
    this.serviceId = '1000',
    this.serviceName = '',
    this.serviceNameHi = '',
    this.districtId,
    this.districtName,
    this.districtNameHi,
    this.blockId,
    this.blockName,
    this.blockNameHi,
    this.selectedRural,
    this.selectedRuralId,
  });

  final DateTime startDate;
  final DateTime endDate;
  final String serviceId;
  final String serviceName;
  final String serviceNameHi;
  final String? districtId;
  final String? districtName;
  final String? districtNameHi;
  final String? blockId;
  final String? blockName;
  final String? blockNameHi;
  final String? selectedRural;
  /// 0 = Urban, 1 = Rural (matches web `selectedRuralId`).
  final int? selectedRuralId;

  bool get hasService => serviceId != '1000' && serviceId.isNotEmpty;

  bool get hasDistrict =>
      districtId != null && districtId!.trim().isNotEmpty;

  bool get hasBlock => blockId != null && blockId!.trim().isNotEmpty;

  String get isoStartDate => _fmtDate(startDate);

  String get isoEndDate => _fmtDate(endDate);

  String localizedServiceName(BuildContext context) =>
      context.lb(serviceName, serviceNameHi);

  String localizedDistrictName(BuildContext context) =>
      context.lb(districtName ?? '', districtNameHi ?? '');

  String localizedBlockName(BuildContext context) =>
      context.lb(blockName ?? '', blockNameHi ?? '');

  String localizedSelectedRural(BuildContext context) =>
      localizedAreaLabel(context, selectedRural);

  ReportDrillLevel get drillLevel {
    // Rural → block count (terminal for beneficiary — no member list).
    if (hasService && hasDistrict && selectedRural == 'Rural') {
      return ReportDrillLevel.blocks;
    }
    // Urban selection no longer opens beneficiary list; stay on area count.
    if (hasService && hasDistrict && selectedRural == 'Urban') {
      return ReportDrillLevel.ruralUrban;
    }
    if (hasService && hasDistrict) {
      return ReportDrillLevel.ruralUrban;
    }
    if (hasService) {
      return ReportDrillLevel.districts;
    }
    return ReportDrillLevel.allServices;
  }

  ReportFilterState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? serviceId,
    String? serviceName,
    String? serviceNameHi,
    String? districtId,
    String? districtName,
    String? districtNameHi,
    String? blockId,
    String? blockName,
    String? blockNameHi,
    String? selectedRural,
    int? selectedRuralId,
    bool clearDistrict = false,
    bool clearBlock = false,
    bool clearRural = false,
  }) {
    return ReportFilterState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      serviceNameHi: serviceNameHi ?? this.serviceNameHi,
      districtId: clearDistrict ? null : (districtId ?? this.districtId),
      districtName: clearDistrict ? null : (districtName ?? this.districtName),
      districtNameHi:
          clearDistrict ? null : (districtNameHi ?? this.districtNameHi),
      blockId: clearBlock ? null : (blockId ?? this.blockId),
      blockName: clearBlock ? null : (blockName ?? this.blockName),
      blockNameHi: clearBlock ? null : (blockNameHi ?? this.blockNameHi),
      selectedRural: clearRural ? null : (selectedRural ?? this.selectedRural),
      selectedRuralId:
          clearRural ? null : (selectedRuralId ?? this.selectedRuralId),
    );
  }

  static ReportFilterState defaultRange() {
    final now = DateTime.now();
    return ReportFilterState(
      startDate: DateTime(now.year, now.month, 1),
      endDate: now,
    );
  }

  static String _fmtDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

enum ReportDrillLevel {
  allServices,
  districts,
  ruralUrban,
  blocks,
  beneficiaries,
}
