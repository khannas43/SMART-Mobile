import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../i18n/app_locale.dart';
import '../../services/api_error_util.dart';
import '../../services/citizen_navigation.dart';
import '../../services/consent_service.dart';
import '../../services/eligible_service.dart';
import '../../widgets/consent/consent_list_table.dart';
import '../../widgets/consent/scheme_verification_sheet.dart';
import '../../widgets/data_screen_states.dart';

/// Consent management with Provide / View tabs (web eligibleSchemes + viewConsent).
class CitizenConsentScreen extends StatefulWidget {
  const CitizenConsentScreen({
    super.key,
    this.initialSection = ConsentSection.provide,
  });

  final ConsentSection initialSection;

  @override
  State<CitizenConsentScreen> createState() => _CitizenConsentScreenState();
}

class _CitizenConsentScreenState extends State<CitizenConsentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  var _viewPage = 1;
  var _viewLoading = true;
  var _eligibleLoading = true;
  String? _viewError;
  String? _eligibleError;
  List<Map<String, dynamic>> _viewRows = const [];
  List<Map<String, dynamic>> _eligibleRows = const [];
  var _viewTotal = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialSection == ConsentSection.view ? 1 : 0,
    );
    _tabController.addListener(_onTabChanged);
    _loadForCurrentTab();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _loadForCurrentTab();
  }

  Future<void> _loadForCurrentTab() async {
    if (_tabController.index == 0) {
      await _loadEligible();
    } else {
      await _loadView();
    }
  }

  Future<void> _refreshCurrentTab() => _loadForCurrentTab();

  Future<void> _loadEligible() async {
    setState(() {
      _eligibleLoading = true;
      _eligibleError = null;
    });
    try {
      final result = await EligibleService.instance.fetchEligibleServices();
      if (!mounted) return;
      setState(() {
        _eligibleRows = result.rows;
        _eligibleLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _eligibleError = ApiErrorUtil.friendlyMessage(e);
        _eligibleLoading = false;
      });
    }
  }

  Future<void> _loadView() async {
    setState(() {
      _viewLoading = true;
      _viewError = null;
    });
    try {
      final result = await ConsentService.instance.fetchConsents(page: _viewPage);
      if (!mounted) return;
      setState(() {
        _viewRows = result.rows;
        _viewTotal = result.total;
        _viewLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _viewError = ApiErrorUtil.friendlyMessage(e);
        _viewLoading = false;
      });
    }
  }

  Future<void> _openProvideConsent(Map<String, dynamic> row) async {
    await SchemeVerificationSheet.show(
      context,
      eligibleRow: row,
      onSuccess: () async {
        await _loadEligible();
        await _loadView();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    return Column(
      children: [
        Material(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: kCitizenOrange,
            unselectedLabelColor: kMuted,
            indicatorColor: kCitizenOrange,
            tabs: [
              Tab(text: context.l('Provide Consent', 'सहमति प्रदान करें')),
              Tab(text: context.l('View Consent', 'सहमति देखें')),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              RefreshIndicator(
                onRefresh: _loadEligible,
                color: kCitizenOrange,
                child: _buildProvideTab(context),
              ),
              RefreshIndicator(
                onRefresh: _refreshCurrentTab,
                color: kCitizenOrange,
                child: _buildViewTab(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProvideTab(BuildContext context) {
    if (_eligibleLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [DataScreenStates.loading()],
      );
    }
    if (_eligibleError != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          DataScreenStates.error(
            context: context,
            message: _eligibleError!,
            onRetry: _loadEligible,
          ),
        ],
      );
    }
    if (_eligibleRows.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          DataScreenStates.empty(
            message: context.l(
              'No eligible services found.',
              'कोई पात्र सेवा नहीं मिली।',
            ),
          ),
        ],
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        for (final row in _eligibleRows)
          _EligibleCard(
            row: row,
            onAvail: () => _openProvideConsent(row),
          ),
      ],
    );
  }

  Widget _buildViewTab(BuildContext context) {
    if (_viewLoading && _viewRows.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [DataScreenStates.loading()],
      );
    }
    if (_viewError != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          DataScreenStates.error(
            context: context,
            message: _viewError!,
            onRetry: _loadView,
          ),
        ],
      );
    }
    if (_viewRows.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          DataScreenStates.empty(
            message: context.l(
              'No consent records found.',
              'कोई सहमति रिकॉर्ड नहीं मिला।',
            ),
          ),
        ],
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        ConsentListTable(
          rows: _viewRows,
          page: _viewPage,
          pageSize: ConsentService.pageSize,
          total: _viewTotal,
          loading: _viewLoading,
          onPrev: _viewPage > 1
              ? () {
                  setState(() => _viewPage--);
                  _loadView();
                }
              : null,
          onNext: _viewPage * ConsentService.pageSize < _viewTotal
              ? () {
                  setState(() => _viewPage++);
                  _loadView();
                }
              : null,
        ),
      ],
    );
  }
}

class _EligibleCard extends StatelessWidget {
  const _EligibleCard({required this.row, required this.onAvail});

  final Map<String, dynamic> row;
  final VoidCallback onAvail;

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    final name = row['serviceName']?.toString() ??
        row['nameEn']?.toString() ??
        row['nameHi']?.toString() ??
        '—';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: kBorder),
      ),
      child: ListTile(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          row['status']?.toString() ?? '',
          style: const TextStyle(fontSize: 12, color: kMuted),
        ),
        trailing: FilledButton(
          onPressed: onAvail,
          style: FilledButton.styleFrom(
            backgroundColor: kCitizenOrange,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: Text(
            context.l('Avail Service', 'सेवा प्राप्त करें'),
            style: const TextStyle(fontSize: 11),
          ),
        ),
      ),
    );
  }
}
