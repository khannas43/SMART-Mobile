import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../i18n/app_locale.dart';
import '../../models/report_models.dart';
import '../../models/user_role.dart';
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
  Map<String, ({String en, String hi})> _districtNamesById = const {};
  ReportFilterState _filters = ReportFilterState.defaultRange();
  DateTime? _tempFrom;
  DateTime? _tempTo;
  String _tempServiceId = '1000';
  String _tempServiceName = '';
  String _tempServiceNameHi = '';
  String? _loadedDeptId;
  bool _loading = true;
  bool _loadingServices = true;
  String? _error;
  String? _servicesError;
  var _dataLoadGeneration = 0;
  var _dataLoadInFlight = false;

  List<ServiceOption> get _dropdownServices {
    if (_tempServiceId == '1000') return _services;
    if (_services.any((s) => s.serviceId == _tempServiceId)) {
      return _services;
    }
    if (_tempServiceName.isNotEmpty) {
      return [
        ..._services,
        ServiceOption(
          serviceId: _tempServiceId,
          serviceName: _tempServiceName,
          serviceNameHi: _tempServiceNameHi,
        ),
      ];
    }
    return _services;
  }

  Map<String, ServiceOption> get _servicesById => {
        for (final s in _services) s.serviceId: s,
      };

  ServiceOption? _catalogService(String serviceId) {
    for (final s in _services) {
      if (s.serviceId == serviceId) return s;
    }
    return null;
  }

  void _syncTempFromFilters(ReportFilterState filters) {
    _tempFrom = filters.startDate;
    _tempTo = filters.endDate;
    _tempServiceId = filters.serviceId;
    _tempServiceName = filters.serviceName;
    _tempServiceNameHi = filters.serviceNameHi;
  }

  @override
  void initState() {
    super.initState();
    _filters = RoleContext.instance.reportFilter;
    _syncTempFromFilters(_filters);
    _loadedDeptId = RoleContext.instance.selectedDeptId;
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
    if (RoleContext.instance.activePanel != SmartPanel.department) return;

    final deptId = RoleContext.instance.selectedDeptId;
    final deptChanged = deptId != _loadedDeptId;
    if (deptChanged) {
      _loadedDeptId = deptId;
      _loadServices(resetServiceIfMissing: true);
    }

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
      _syncTempFromFilters(_filters);
    });
    _loadData();
  }

  Future<void> _bootstrap() async {
    if (RoleContext.instance.activePanel != SmartPanel.department) return;
    await RoleContext.instance.syncDepartmentFromMappedList();
    if (RoleContext.instance.activePanel != SmartPanel.department) return;
    _loadedDeptId = RoleContext.instance.selectedDeptId;
    await Future.wait([
      _loadServices(),
      _loadDistrictLookup(),
    ]);
    await _loadData();
  }

  Future<void> _loadDistrictLookup() async {
    final lookup = await SwsReportService.instance.fetchDistrictNameLookup();
    if (!mounted) return;
    setState(() => _districtNamesById = lookup);
  }

  Future<void> _loadServices({bool resetServiceIfMissing = false}) async {
    setState(() {
      _loadingServices = true;
      _servicesError = null;
    });
    try {
      final services = await SwsReportService.instance.fetchServices(
        departmentId: RoleContext.instance.selectedDeptId,
      );
      if (!mounted) return;
      setState(() {
        _services = services;
        _loadingServices = false;

        final appliedMatch = _catalogService(_filters.serviceId);
        if (appliedMatch != null && _filters.hasService) {
          _filters = _filters.copyWith(
            serviceName: appliedMatch.serviceName,
            serviceNameHi: appliedMatch.serviceNameHi,
          );
        } else if (resetServiceIfMissing &&
            _filters.hasService &&
            appliedMatch == null) {
          _filters = _filters.copyWith(
            serviceId: '1000',
            serviceName: '',
            serviceNameHi: '',
            clearDistrict: true,
            clearBlock: true,
            clearRural: true,
          );
          RoleContext.instance.updateReportFilter(_filters);
          _syncTempFromFilters(_filters);
        }

        final pendingMatch = _catalogService(_tempServiceId);
        if (pendingMatch != null && _tempServiceId != '1000') {
          _tempServiceName = pendingMatch.serviceName;
          _tempServiceNameHi = pendingMatch.serviceNameHi;
        } else if (resetServiceIfMissing &&
            _tempServiceId != '1000' &&
            pendingMatch == null) {
          _tempServiceId = '1000';
          _tempServiceName = '';
          _tempServiceNameHi = '';
        }
      });
      if (resetServiceIfMissing &&
          (_filters.serviceId == '1000' || !_filters.hasService)) {
        await _loadData();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _servicesError = ApiErrorUtil.friendlyMessage(e);
        _loadingServices = false;
      });
    }
  }

  List<Map<String, dynamic>> _enrichRows(List<Map<String, dynamic>> rows) {
    return rows.map((row) {
      final enriched = Map<String, dynamic>.from(row);

      // Service: fill Hindi from department catalog when SP row lacks it.
      final serviceId = pickReportField(row, const ['serviceId', 'SERVICE_ID']);
      final catalog = _catalogService(serviceId);
      if (catalog != null) {
        if (serviceNameEnFromRow(enriched).isEmpty &&
            catalog.serviceName.isNotEmpty) {
          enriched['serviceName'] = catalog.serviceName;
        }
        if (serviceNameHiFromRow(enriched).isEmpty &&
            catalog.serviceNameHi.isNotEmpty) {
          enriched['serviceNameHi'] = catalog.serviceNameHi;
        }
      }

      // District: enrich EN/HI from DistrictMaster lookup when available.
      final districtId = pickReportField(row, const [
        'districtId',
        'DISTRICT_ID',
        'districtid',
      ]);
      final lookup = _districtNamesById[districtId];
      if (lookup != null) {
        if (districtNameEnFromRow(enriched).isEmpty && lookup.en.isNotEmpty) {
          enriched['districtName'] = lookup.en;
        }
        if (districtNameHiFromRow(enriched).isEmpty && lookup.hi.isNotEmpty) {
          enriched['districtNameHi'] = lookup.hi;
        }
      }

      return enriched;
    }).toList();
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
        _rows = _enrichRows(rows);
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
    setState(() {
      _filters = next;
      _syncTempFromFilters(next);
    });
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
    final catalog = _catalogService(_tempServiceId);
    _applyFilters(
      _filters.copyWith(
        startDate: _tempFrom ?? _filters.startDate,
        endDate: _tempTo ?? _filters.endDate,
        serviceId: _tempServiceId,
        serviceName: catalog?.serviceName ?? _tempServiceName,
        serviceNameHi: catalog?.serviceNameHi ?? _tempServiceNameHi,
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
      _syncTempFromFilters(fresh);
    });
    RoleContext.instance.resetReportFilter();
    _loadData();
  }

  void _onRowTap(Map<String, dynamic> row) {
    switch (_filters.drillLevel) {
      case ReportDrillLevel.allServices:
        final serviceId = _pick(row, const ['serviceId', 'SERVICE_ID']);
        final rowEn = serviceNameEnFromRow(row);
        final rowHi = serviceNameHiFromRow(row);
        final catalog = _catalogService(serviceId);
        _applyFilters(
          _filters.copyWith(
            serviceId: serviceId,
            serviceName: rowEn.isNotEmpty
                ? rowEn
                : (catalog?.serviceName ?? serviceId),
            serviceNameHi: rowHi.isNotEmpty
                ? rowHi
                : (catalog?.serviceNameHi ?? ''),
            clearDistrict: true,
            clearBlock: true,
            clearRural: true,
          ),
        );
      case ReportDrillLevel.districts:
        final districtId = _numericIdString(
          _pick(row, const ['districtId', 'DISTRICT_ID', 'districtid']),
        );
        final lookup = _districtNamesById[districtId];
        final en = districtNameEnFromRow(row);
        final hi = districtNameHiFromRow(row);
        _applyFilters(
          _filters.copyWith(
            districtId: districtId,
            districtName: en.isNotEmpty ? en : (lookup?.en ?? ''),
            districtNameHi: hi.isNotEmpty ? hi : (lookup?.hi ?? ''),
            clearBlock: true,
            clearRural: true,
          ),
        );
      case ReportDrillLevel.ruralUrban:
        // Use raw API area value (not localized label). Existing conditions:
        // Urban Count is terminal; Rural drills to block-wise count.
        final area = areaRawFromRow(row);
        if (isUrbanAreaValue(area)) {
          break;
        }
        _applyFilters(
          _filters.copyWith(
            // Always store English for API / drillLevel comparisons.
            selectedRural: 'Rural',
            selectedRuralId: 1,
            clearBlock: true,
          ),
        );
      case ReportDrillLevel.blocks:
        // Block Count is terminal — do not open Beneficiary Details.
        break;
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
            serviceNameHi: '',
            clearDistrict: true,
            clearBlock: true,
            clearRural: true,
          ),
        );
      case ReportDrillLevel.allServices:
        break;
    }
  }

  /// Normalize JDBC/BigDecimal-style ids ("101.0") before storing on filters.
  String _numericIdString(String raw) {
    if (raw.trim().isEmpty) return '';
    final asInt = int.tryParse(raw.trim());
    if (asInt != null) return asInt.toString();
    final asDouble = double.tryParse(raw.trim());
    if (asDouble != null) return asDouble.toInt().toString();
    return raw.trim();
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
        await Future.wait([
          _loadServices(),
          _loadDistrictLookup(),
        ]);
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
            pendingServiceId: _tempServiceId,
            tempFrom: _tempFrom,
            tempTo: _tempTo,
            loadingServices: _loadingServices,
            servicesError: _servicesError,
            onServiceChanged: (svc) {
              if (svc == null) return;
              setState(() {
                _tempServiceId = svc.serviceId;
                _tempServiceName = svc.serviceName;
                _tempServiceNameHi = svc.serviceNameHi;
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
            servicesById: _servicesById,
            onResetAll: () => _applyFilters(
              _filters.copyWith(
                serviceId: '1000',
                serviceName: '',
                serviceNameHi: '',
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
              servicesById: _servicesById,
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
