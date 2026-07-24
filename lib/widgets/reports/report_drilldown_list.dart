import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../i18n/app_locale.dart';
import '../../models/report_models.dart';

class ReportDrilldownList extends StatelessWidget {
  const ReportDrilldownList({
    super.key,
    required this.level,
    required this.rows,
    required this.onRowTap,
    this.totalField = 'totalRecord',
    this.servicesById = const {},
  });

  final ReportDrillLevel level;
  final List<Map<String, dynamic>> rows;
  final void Function(Map<String, dynamic> row) onRowTap;
  final String totalField;
  final Map<String, ServiceOption> servicesById;

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    if (rows.isEmpty) return const SizedBox.shrink();

    final titleKey = _titleKey(level);
    final valueKey = _valueKey(level);
    final total = rows.fold<num>(
      0,
      (sum, r) => sum + (_num(r[totalField]) ?? _num(r['beneficiaries']) ?? 0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _sectionTitle(context, level),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...rows.map((row) {
          final title = _rowTitle(context, row, titleKey);
          final count = _num(row[valueKey]) ?? _num(row[totalField]) ?? 0;
          final drillable = _isRowDrillable(row);
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: kBorder),
            ),
            child: ListTile(
              title: Text(
                title,
                style: TextStyle(
                  color: drillable ? kPrimaryRoyal : kText,
                  decoration:
                      drillable ? TextDecoration.underline : TextDecoration.none,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Text(
                count.toString(),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onTap: drillable ? () => onRowTap(row) : null,
            ),
          );
        }),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kBlueL,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l('Total Records', 'कुल रिकॉर्ड'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                total.toString(),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _rowTitle(
    BuildContext context,
    Map<String, dynamic> row,
    String titleKey,
  ) {
    switch (level) {
      case ReportDrillLevel.allServices:
        final fromRow = localizedServiceTitleFromRow(context, row);
        if (fromRow.isNotEmpty && fromRow != '—') return fromRow;
        // Fallback to catalog if SP row lacks names.
        final serviceId = _str(row['serviceId'] ?? row['SERVICE_ID']);
        return localizedServiceLabel(
          context,
          serviceId: serviceId == '—' ? null : serviceId,
          fallbackEn: _str(row[titleKey]),
          byId: servicesById,
        );
      case ReportDrillLevel.districts:
        final title = localizedDistrictTitleFromRow(context, row);
        return title.isNotEmpty ? title : _str(row[titleKey]);
      case ReportDrillLevel.ruralUrban:
        final raw = areaRawFromRow(row);
        return localizedAreaLabel(context, raw.isEmpty ? null : raw);
      case ReportDrillLevel.blocks:
        final title = localizedBlockTitleFromRow(context, row);
        return title.isNotEmpty ? title : _str(row[titleKey]);
      case ReportDrillLevel.beneficiaries:
        return _str(row[titleKey]);
    }
  }

  /// Urban area rows and all block rows are terminal (no beneficiary drill).
  /// Detection uses raw API area fields — not localized display labels.
  bool _isRowDrillable(Map<String, dynamic> row) {
    if (level == ReportDrillLevel.blocks) return false;
    if (level == ReportDrillLevel.beneficiaries) return false;
    if (level == ReportDrillLevel.ruralUrban) {
      // Rural → drill to block count; Urban → terminal (existing conditions).
      return !isUrbanAreaValue(areaRawFromRow(row));
    }
    return true;
  }

  String _sectionTitle(BuildContext context, ReportDrillLevel level) =>
      switch (level) {
        ReportDrillLevel.allServices =>
          context.l('Service Report', 'सेवा रिपोर्ट'),
        ReportDrillLevel.districts => context.l(
          'District Wise Beneficiary Count',
          'जिलेवार लाभार्थी संख्या',
        ),
        ReportDrillLevel.ruralUrban =>
          context.l('Area Wise Count', 'क्षेत्रवार संख्या'),
        ReportDrillLevel.blocks => context.l(
          'Block Wise Beneficiary Count',
          'ब्लॉकवार लाभार्थी संख्या',
        ),
        ReportDrillLevel.beneficiaries =>
          context.l('Beneficiary List', 'लाभार्थी सूची'),
      };

  String _titleKey(ReportDrillLevel level) => switch (level) {
        ReportDrillLevel.allServices => 'serviceName',
        ReportDrillLevel.districts => 'districtName',
        ReportDrillLevel.ruralUrban => 'areaName',
        ReportDrillLevel.blocks => 'blockName',
        ReportDrillLevel.beneficiaries => 'memberName',
      };

  String _valueKey(ReportDrillLevel level) => switch (level) {
        ReportDrillLevel.allServices => 'beneficiaries',
        _ => 'totalRecord',
      };

  String _str(dynamic v) => v?.toString() ?? '—';

  num? _num(dynamic v) {
    if (v is num) return v;
    return num.tryParse(v?.toString() ?? '');
  }
}
