import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../i18n/app_locale.dart';
import '../../models/report_models.dart';
import '../../services/api_error_util.dart';
import '../../services/reports/sws_report_service.dart';
import '../../services/role/role_context.dart';
import '../../widgets/data_screen_states.dart';
import '../../widgets/reports/report_breadcrumb.dart';
import '../../widgets/reports/report_drilldown_list.dart';
import '../../widgets/reports/report_filter_card.dart';

/// Full-screen hierarchical reports (UAT /department/report parity).
class ReportDrilldownScreen extends StatefulWidget {
  const ReportDrilldownScreen({super.key});

  @override
  State<ReportDrilldownScreen> createState() => _ReportDrilldownScreenState();
}

class _ReportDrilldownScreenState extends State<ReportDrilldownScreen> {
  List<ServiceOption> _services = const [];
  List<Map<String, dynamic>> _rows = const [];
  ReportFilterState _filters = ReportFilterState.defaultRange();
  DateTime? _tempFrom;
  DateTime? _tempTo;
  bool _loading = true;
  bool _loadingServices = true;
  String? _error;
  String? _servicesError;
  var _dataLoadGeneration = 0;
  var _dataLoadInFlight = false;

  List<ServiceOption> get _dropdownServices {
    if (_filters.serviceId == '1000') return _services;
    if (_services.any((s) => s.serviceId == _filters.serviceId)) {
      return _services;
    }
    if (_filters.serviceName.isNotEmpty) {
      return [
        ..._services,
        ServiceOption(
          serviceId: _filters.serviceId,
          serviceName: _filters.serviceName,
        ),
      ];
    }
    return _services;
  }

  @override
  void initState() {
    super.initState();
    _filters = RoleContext.instance.reportFilter;
    _tempFrom = _filters.startDate;
    _tempTo = _filters.endDate;
    _bootstrap();
    RoleContext.instance.addListener(_onRoleChanged);
  }

  @override
  void dispose() {
    RoleContext.instance.removeListener(_onRoleChanged);
    super.dispose();
  }

  void _onRoleChanged() {
    if (!mounted) return;
    final next = RoleContext.instance.reportFilter;
    final filtersChanged = next.serviceId != _filters.serviceId ||
        next.districtId != _filters.districtId ||
        next.blockId != _filters.blockId ||
        next.selectedRural != _filters.selectedRural ||
        next.startDate != _filters.startDate ||
        next.endDate != _filters.endDate;
    if (!filtersChanged) return;
    setState(() {
      _filters = next;
      _tempFrom = _filters.startDate;
      _tempTo = _filters.endDate;
    });
    _loadData();
  }

  Future<void> _bootstrap() async {
    await RoleContext.instance.syncDepartmentFromMappedList();
    await _loadServices();
    await _loadData();
  }

  Future<void> _loadServices() async {
    setState(() {
      _loadingServices = true;
      _servicesError = null;
    });
    try {
      final services = await SwsReportService.instance.fetchServices();
      if (!mounted) return;
      setState(() {
        _services = services;
        _loadingServices = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _servicesError = ApiErrorUtil.friendlyMessage(e);
        _loadingServices = false;
      });
    }
  }

  Future<void> _loadData() async {
    if (_dataLoadInFlight) return;
    _dataLoadInFlight = true;
    final generation = ++_dataLoadGeneration;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await SwsReportService.instance.fetchForLevel(_filters);
      if (!mounted || generation != _dataLoadGeneration) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || generation != _dataLoadGeneration) return;
      setState(() {
        _error = ApiErrorUtil.friendlyMessage(e);
        _loading = false;
      });
    } finally {
      _dataLoadInFlight = false;
    }
  }

  void _applyFilters(ReportFilterState next) {
    setState(() => _filters = next);
    RoleContext.instance.updateReportFilter(next);
    _loadData();
  }

  void _onSubmit() {
    if (_tempFrom != null && _tempTo != null && _tempFrom!.isAfter(_tempTo!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l(
            'From Date cannot be greater than To Date',
            'प्रारंभ तिथि समाप्ति तिथि से बड़ी नहीं हो सकती',
          )),
        ),
      );
      return;
    }
    _applyFilters(
      _filters.copyWith(
        startDate: _tempFrom ?? _filters.startDate,
        endDate: _tempTo ?? _filters.endDate,
        clearDistrict: true,
        clearBlock: true,
        clearRural: true,
      ),
    );
  }

  void _onReset() {
    final fresh = ReportFilterState.defaultRange();
    setState(() {
      _filters = fresh;
      _tempFrom = fresh.startDate;
      _tempTo = fresh.endDate;
    });
    RoleContext.instance.resetReportFilter();
    _loadData();
  }

  void _onRowTap(Map<String, dynamic> row) {
    switch (_filters.drillLevel) {
      case ReportDrillLevel.allServices:
        _applyFilters(
          _filters.copyWith(
            serviceId: _pick(row, const ['serviceId', 'SERVICE_ID']),
            serviceName: _pick(row, const ['serviceName', 'SERVICE_NAME']),
            clearDistrict: true,
            clearBlock: true,
            clearRural: true,
          ),
        );
      case ReportDrillLevel.districts:
        _applyFilters(
          _filters.copyWith(
            districtId: _pick(row, const ['districtId', 'DISTRICT_ID', 'districtid']),
            districtName: _pick(row, const ['districtName', 'DISTRICT_NAME']),
            clearBlock: true,
            clearRural: true,
          ),
        );
      case ReportDrillLevel.ruralUrban:
        final area = _pick(row, const ['areaName', 'AREA_NAME']);
        if (_isUrbanArea(area)) {
          // Web: Urban → MemberList directly (blockId cleared / 0).
          _applyFilters(
            _filters.copyWith(
              selectedRural: 'Urban',
              selectedRuralId: 0,
              clearBlock: true,
            ),
          );
        } else {
          _applyFilters(
            _filters.copyWith(
              selectedRural: 'Rural',
              selectedRuralId: 1,
              clearBlock: true,
            ),
          );
        }
      case ReportDrillLevel.blocks:
        _applyFilters(
          _filters.copyWith(
            blockId: _pick(row, const ['blockId', 'BLOCK_ID', 'blockid']),
            blockName: _pick(row, const ['blockName', 'BLOCK_NAME']),
          ),
        );
      case ReportDrillLevel.beneficiaries:
        break;
    }
  }

  void _onBack() {
    switch (_filters.drillLevel) {
      case ReportDrillLevel.beneficiaries:
        if (_filters.selectedRural == 'Urban') {
          _applyFilters(
            _filters.copyWith(clearRural: true, clearBlock: true),
          );
        } else {
          _applyFilters(_filters.copyWith(clearBlock: true));
        }
      case ReportDrillLevel.blocks:
        _applyFilters(_filters.copyWith(clearRural: true, clearBlock: true));
      case ReportDrillLevel.ruralUrban:
        _applyFilters(
          _filters.copyWith(
            clearDistrict: true,
            clearBlock: true,
            clearRural: true,
          ),
        );
      case ReportDrillLevel.districts:
        _applyFilters(
          _filters.copyWith(
            serviceId: '1000',
            serviceName: '',
            clearDistrict: true,
            clearBlock: true,
            clearRural: true,
          ),
        );
      case ReportDrillLevel.allServices:
        break;
    }
  }

  bool _isUrbanArea(String area) {
    final normalized = area.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return normalized == 'urban' ||
        normalized.contains('urban') ||
        normalized.contains('शहरी');
  }

  String _pick(Map<String, dynamic> row, List<String> keys) {
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

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    return RefreshIndicator(
      onRefresh: () async {
        await _loadServices();
        await _loadData();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              if (_filters.drillLevel != ReportDrillLevel.allServices)
                IconButton(
                  tooltip: context.l('Back', 'वापस'),
                  onPressed: _onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              Expanded(
                child: Text(
                  context.l('Reports', 'रिपोर्ट'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ReportFilterCard(
            services: _dropdownServices,
            filters: _filters,
            tempFrom: _tempFrom,
            tempTo: _tempTo,
            loadingServices: _loadingServices,
            servicesError: _servicesError,
            onServiceChanged: (svc) {
              if (svc == null) return;
              setState(() {
                _filters = _filters.copyWith(
                  serviceId: svc.serviceId,
                  serviceName: svc.serviceName,
                  clearDistrict: true,
                  clearBlock: true,
                  clearRural: true,
                );
              });
            },
            onFromChanged: (d) => setState(() => _tempFrom = d),
            onToChanged: (d) => setState(() => _tempTo = d),
            onSubmit: _onSubmit,
            onReset: _onReset,
          ),
          const SizedBox(height: 12),
          ReportBreadcrumb(
            filters: _filters,
            onResetAll: () => _applyFilters(
              _filters.copyWith(
                serviceId: '1000',
                serviceName: '',
                clearDistrict: true,
                clearBlock: true,
                clearRural: true,
              ),
            ),
            onResetToService: () => _applyFilters(
              _filters.copyWith(
                clearDistrict: true,
                clearBlock: true,
                clearRural: true,
              ),
            ),
            onResetToDistrict: () => _applyFilters(
              _filters.copyWith(clearBlock: true, clearRural: true),
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            DataScreenStates.error(context: context, message: _error!, onRetry: _loadData)
          else if (_rows.isEmpty)
            DataScreenStates.empty(
              message: context.l('No records found.', 'कोई रिकॉर्ड नहीं मिला।'),
            )
          else if (_filters.drillLevel == ReportDrillLevel.beneficiaries)
            _BeneficiaryList(rows: _rows)
          else
            ReportDrilldownList(
              level: _filters.drillLevel,
              rows: _rows,
              onRowTap: _onRowTap,
            ),
        ],
      ),
    );
  }
}

class _BeneficiaryList extends StatelessWidget {
  const _BeneficiaryList({required this.rows});

  final List<Map<String, dynamic>> rows;

  static const _columns = [
    ('memberName', 'Member Name', 'सदस्य का नाम'),
    ('memberId', 'Member Id', 'सदस्य आईडी'),
    ('memberFatherName', 'Father Name', 'पिता का नाम'),
    ('memberMotherName', 'Mother Name', 'माता का नाम'),
    ('eventDate', 'Event Date', 'घटना तिथि'),
    ('stockholderUpdateDate', 'Availed On', 'प्राप्त तिथि'),
  ];

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l('Member List Report', 'सदस्य सूची रिपोर्ट'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          context.l(
            'Total Members: ${rows.length}',
            'कुल सदस्य: ${rows.length}',
          ),
          style: const TextStyle(fontSize: 13, color: kMuted),
        ),
        const SizedBox(height: 10),
        for (final row in rows)
          Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: kBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final col in _columns)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l(col.$2, col.$3),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: kMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _cell(row, col.$1),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _cell(Map<String, dynamic> row, String key) {
    for (final entry in row.entries) {
      if (entry.key.toLowerCase() == key.toLowerCase()) {
        final value = entry.value;
        if (value == null) return '—';
        return value.toString();
      }
    }
    return '—';
  }
}
