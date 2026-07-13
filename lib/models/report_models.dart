/// Sws101 report types (matches smart_frontend Sws101ReportsPage).
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
  });

  final String serviceId;
  final String serviceName;

  factory ServiceOption.fromRow(Map<String, dynamic> row) {
    final id = _pick(row, const ['serviceId', 'SERVICE_ID', 'id', 'ID']);
    final name = _pick(row, const [
      'serviceName',
      'SERVICE_NAME',
      'nameEn',
      'NAME_EN',
    ]);
    return ServiceOption(
      serviceId: id,
      serviceName: name.isNotEmpty ? name : 'Service $id',
    );
  }

  static String _pick(Map<String, dynamic> row, List<String> keys) {
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
}

class ReportFilterState {
  const ReportFilterState({
    required this.startDate,
    required this.endDate,
    this.serviceId = '1000',
    this.serviceName = '',
    this.districtId,
    this.districtName,
    this.blockId,
    this.blockName,
    this.selectedRural,
    this.selectedRuralId,
  });

  final DateTime startDate;
  final DateTime endDate;
  final String serviceId;
  final String serviceName;
  final String? districtId;
  final String? districtName;
  final String? blockId;
  final String? blockName;
  final String? selectedRural;
  /// 0 = Urban, 1 = Rural (matches web `selectedRuralId`).
  final int? selectedRuralId;

  bool get hasService => serviceId != '1000' && serviceId.isNotEmpty;

  bool get hasDistrict =>
      districtId != null && districtId!.trim().isNotEmpty;

  bool get hasBlock => blockId != null && blockId!.trim().isNotEmpty;

  String get isoStartDate => _fmtDate(startDate);

  String get isoEndDate => _fmtDate(endDate);

  ReportDrillLevel get drillLevel {
    if (hasService && hasDistrict && hasBlock) {
      return ReportDrillLevel.beneficiaries;
    }
    if (hasService && hasDistrict && selectedRural == 'Rural') {
      return ReportDrillLevel.blocks;
    }
    if (hasService && hasDistrict && selectedRural == 'Urban') {
      return ReportDrillLevel.beneficiaries;
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
    String? districtId,
    String? districtName,
    String? blockId,
    String? blockName,
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
      districtId: clearDistrict ? null : (districtId ?? this.districtId),
      districtName: clearDistrict ? null : (districtName ?? this.districtName),
      blockId: clearBlock ? null : (blockId ?? this.blockId),
      blockName: clearBlock ? null : (blockName ?? this.blockName),
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
