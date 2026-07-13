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

class CitizenConsentScreen extends StatefulWidget {
  const CitizenConsentScreen({super.key});

  @override
  State<CitizenConsentScreen> createState() => _CitizenConsentScreenState();
}

class _CitizenConsentScreenState extends State<CitizenConsentScreen> {
  final _scrollController = ScrollController();
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
    CitizenNavigation.instance.addListener(_onNavigation);
    _loadAll();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyNavigationFocus());
  }

  @override
  void dispose() {
    CitizenNavigation.instance.removeListener(_onNavigation);
    _scrollController.dispose();
    super.dispose();
  }

  void _onNavigation() {
    if (!mounted) return;
    _applyNavigationFocus();
  }

  void _applyNavigationFocus() {
    final section = CitizenNavigation.instance.consumePendingConsentSection();
    if (section == ConsentSection.view) {
      _scrollController.animateTo(
        400,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadEligible(), _loadView()]);
  }

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
      onSuccess: _loadAll,
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    return RefreshIndicator(
      onRefresh: _loadAll,
      color: kCitizenOrange,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(
            context.l('Provide Consent', 'सहमति प्रदान करें'),
            Icons.add_task_outlined,
          ),
          const SizedBox(height: 8),
          if (_eligibleLoading)
            DataScreenStates.loading()
          else if (_eligibleError != null)
            DataScreenStates.error(
              context: context,
              message: _eligibleError!,
              onRetry: _loadEligible,
            )
          else if (_eligibleRows.isEmpty)
            DataScreenStates.empty(
              message: context.l(
                'No eligible services found.',
                'कोई पात्र सेवा नहीं मिली।',
              ),
            )
          else
            ..._eligibleRows.map((row) => _EligibleCard(
                  row: row,
                  onAvail: () => _openProvideConsent(row),
                )),
          const SizedBox(height: 24),
          _sectionTitle(
            context.l('View All Consents', 'सभी सहमतियाँ देखें'),
            Icons.fact_check_outlined,
          ),
          const SizedBox(height: 8),
          if (_viewLoading && _viewRows.isEmpty)
            DataScreenStates.loading()
          else if (_viewError != null)
            DataScreenStates.error(
              context: context,
              message: _viewError!,
              onRetry: _loadView,
            )
          else if (_viewRows.isEmpty)
            DataScreenStates.empty(
              message: context.l(
                'No consent records found.',
                'कोई सहमति रिकॉर्ड नहीं मिला।',
              ),
            )
          else
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
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: kCitizenOrange),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: kText,
            ),
          ),
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
