import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../i18n/app_locale.dart';
import '../../models/report_models.dart';

class ReportFilterSheet extends StatefulWidget {
  const ReportFilterSheet({
    super.key,
    required this.filters,
    required this.services,
    required this.districtOptions,
    required this.blockOptions,
    required this.reportType,
    required this.onApply,
  });

  final ReportFilterState filters;
  final List<ServiceOption> services;
  final List<MapEntry<String, String>> districtOptions;
  final List<MapEntry<String, String>> blockOptions;
  final SwsReportType reportType;
  final ValueChanged<ReportFilterState> onApply;

  static Future<void> show(
    BuildContext context, {
    required ReportFilterState filters,
    required List<ServiceOption> services,
    required List<MapEntry<String, String>> districtOptions,
    required List<MapEntry<String, String>> blockOptions,
    required SwsReportType reportType,
    required ValueChanged<ReportFilterState> onApply,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ReportFilterSheet(
        filters: filters,
        services: services,
        districtOptions: districtOptions,
        blockOptions: blockOptions,
        reportType: reportType,
        onApply: onApply,
      ),
    );
  }

  @override
  State<ReportFilterSheet> createState() => _ReportFilterSheetState();
}

class _ReportFilterSheetState extends State<ReportFilterSheet> {
  late DateTime _start;
  late DateTime _end;
  late String _serviceId;
  late String _serviceName;
  String? _districtId;
  String? _districtName;
  String? _blockId;
  String? _blockName;

  @override
  void initState() {
    super.initState();
    _start = widget.filters.startDate;
    _end = widget.filters.endDate;
    _serviceId = widget.filters.serviceId;
    _serviceName = widget.filters.serviceName;
    _districtId = widget.filters.districtId;
    _districtName = widget.filters.districtName;
    _blockId = widget.filters.blockId;
    _blockName = widget.filters.blockName;
  }

  Future<void> _pickDate({required bool start}) async {
    final initial = start ? _start : _end;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l('Report Filters', 'रिपोर्ट फ़िल्टर'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickDate(start: true),
                  child: Text(
                    context.l('From', 'से') +
                        ': ${_start.day}/${_start.month}/${_start.year}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickDate(start: false),
                  child: Text(
                    context.l('To', 'तक') + ': ${_end.day}/${_end.month}/${_end.year}',
                  ),
                ),
              ),
            ],
          ),
          if (widget.reportType.requiresService) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _serviceId,
              decoration: InputDecoration(
                labelText: context.l('Service', 'सेवा'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: widget.services
                  .map(
                    (s) => DropdownMenuItem(
                      value: s.serviceId,
                      child: Text(s.serviceName, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (id) {
                if (id == null) return;
                final service = widget.services.firstWhere(
                  (s) => s.serviceId == id,
                  orElse: () => ServiceOption(serviceId: id, serviceName: id),
                );
                setState(() {
                  _serviceId = id;
                  _serviceName = service.serviceName;
                  _districtId = null;
                  _districtName = null;
                  _blockId = null;
                  _blockName = null;
                });
              },
            ),
          ],
          if (widget.reportType.requiresDistrict &&
              widget.districtOptions.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _districtId,
              decoration: InputDecoration(
                labelText: context.l('District', 'जिला'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: widget.districtOptions
                  .map(
                    (d) => DropdownMenuItem(
                      value: d.key,
                      child: Text(d.value),
                    ),
                  )
                  .toList(),
              onChanged: (id) {
                if (id == null) return;
                final name = widget.districtOptions
                    .firstWhere((d) => d.key == id)
                    .value;
                setState(() {
                  _districtId = id;
                  _districtName = name;
                  _blockId = null;
                  _blockName = null;
                });
              },
            ),
          ],
          if (widget.reportType.requiresBlock &&
              widget.blockOptions.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _blockId,
              decoration: InputDecoration(
                labelText: context.l('Block', 'ब्लॉक'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: widget.blockOptions
                  .map(
                    (b) => DropdownMenuItem(
                      value: b.key,
                      child: Text(b.value),
                    ),
                  )
                  .toList(),
              onChanged: (id) {
                if (id == null) return;
                final name =
                    widget.blockOptions.firstWhere((b) => b.key == id).value;
                setState(() {
                  _blockId = id;
                  _blockName = name;
                });
              },
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kPrimaryRoyal),
            onPressed: () {
              widget.onApply(
                widget.filters.copyWith(
                  startDate: _start,
                  endDate: _end,
                  serviceId: _serviceId,
                  serviceName: _serviceName,
                  districtId: _districtId,
                  districtName: _districtName,
                  blockId: _blockId,
                  blockName: _blockName,
                  clearDistrict: _districtId == null,
                  clearBlock: _blockId == null,
                ),
              );
              Navigator.pop(context);
            },
            child: Text(context.l('Apply Filters', 'फ़िल्टर लागू करें')),
          ),
        ],
      ),
    );
  }
}
