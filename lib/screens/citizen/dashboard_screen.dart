import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../i18n/app_locale.dart';
import '../../models/citizen_dashboard_counts.dart';
import '../../services/auth_service.dart';
import '../../services/api_error_util.dart';
import '../../services/citizen_navigation.dart';
import '../../services/dashboard/dashboard_service.dart';
import '../../widgets/shared/action_required.dart';
import '../../widgets/shell/stat_card.dart';
import '../../widgets/data_screen_states.dart';

class CitizenDashboardScreen extends StatefulWidget {
  const CitizenDashboardScreen({super.key});

  @override
  State<CitizenDashboardScreen> createState() => _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen> {
  bool _loading = true;
  String? _error;
  CitizenDashboardCounts _counts = CitizenDashboardCounts.zero;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final counts = await DashboardService.instance.fetchCitizenCounts();
      if (!mounted) return;
      setState(() {
        _counts = counts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiErrorUtil.friendlyMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    final needsEnrollment =
        (AuthService.instance.smUserId ?? '').trim().isEmpty;

    return RefreshIndicator(
      onRefresh: _load,
      color: kCitizenOrange,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            context.l('Dashboard', 'डैशबोर्ड'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: kText,
            ),
          ),
          const Divider(height: 24),
          if (needsEnrollment) const ActionRequired(),
          if (_loading)
            DataScreenStates.loading()
          else if (_error != null)
            DataScreenStates.error(context: context, message: _error!, onRetry: _load)
          else ...[
            _QuickActions(),
            const SizedBox(height: 24),
            StatSection(
              titleEn: 'Service Status',
              titleHi: 'सेवा स्थिति',
              cards: [
                StatCardData(
                  labelEn: 'Eligible Services',
                  labelHi: 'पात्र सेवाएं',
                  value: '${_counts.eligibleCount}',
                  icon: Icons.check_circle_outline,
                  color: Colors.blue.shade700,
                  bgColor: Colors.blue.shade50,
                  barColor: Colors.blue.shade500,
                  onTap: CitizenNavigation.instance.goToProvideConsent,
                ),
                StatCardData(
                  labelEn: 'Total Services Availed',
                  labelHi: 'कुल प्राप्त सेवाएं',
                  value: '${_counts.availedCount}',
                  icon: Icons.person_add_alt_1_outlined,
                  color: Colors.green.shade700,
                  bgColor: Colors.green.shade50,
                  barColor: Colors.green.shade500,
                  onTap: CitizenNavigation.instance.goToAvailedServices,
                ),
                StatCardData(
                  labelEn: 'Total Consents Submitted',
                  labelHi: 'कुल सहमति जमा',
                  value: '${_counts.consentCount}',
                  icon: Icons.collections_bookmark_outlined,
                  color: Colors.purple.shade700,
                  bgColor: Colors.purple.shade50,
                  barColor: Colors.purple.shade400,
                  onTap: CitizenNavigation.instance.goToViewConsents,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l('Quick Actions', 'त्वरित क्रियाएं'),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: kText,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _QuickActionChip(
              icon: Icons.fact_check_outlined,
              label: context.l('Provide Consent', 'सहमति दें'),
              onTap: CitizenNavigation.instance.goToProvideConsent,
            ),
            _QuickActionChip(
              icon: Icons.playlist_add_check_outlined,
              label: context.l('Availed Services', 'प्राप्त सेवाएं'),
              onTap: CitizenNavigation.instance.goToAvailedServices,
            ),
            _QuickActionChip(
              icon: Icons.collections_bookmark_outlined,
              label: context.l('View Consent', 'सहमति देखें'),
              onTap: CitizenNavigation.instance.goToViewConsents,
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: kCitizenOrange),
      label: Text(label),
      onPressed: onTap,
      side: const BorderSide(color: kBorder),
      backgroundColor: Colors.white,
    );
  }
}
