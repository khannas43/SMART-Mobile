import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../i18n/app_locale.dart';
import '../../models/citizen_profile.dart';
import '../../services/smart_api_service.dart';
import '../../widgets/data_screen_states.dart';
import '../../widgets/profile/profile_field_grid.dart';

class CitizenProfileScreen extends StatefulWidget {
  const CitizenProfileScreen({super.key});

  @override
  State<CitizenProfileScreen> createState() => _CitizenProfileScreenState();
}

class _CitizenProfileScreenState extends State<CitizenProfileScreen> {
  bool _loading = true;
  String? _error;
  CitizenProfile? _profile;

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
      final profile = await SmartApiService.instance.fetchCitizenProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    return RefreshIndicator(
      onRefresh: _load,
      color: kCitizenOrange,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            context.l('Your Profile', 'आपकी प्रोफ़ाइल'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: kText,
            ),
          ),
          const Divider(height: 24),
          if (_loading)
            DataScreenStates.loading()
          else if (_error != null)
            DataScreenStates.error(context: context, message: _error!, onRetry: _load)
          else if (_profile != null) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: kCitizenOrange.withValues(alpha: 0.15),
                  child: Text(
                    _profile!.displayNameEn.isNotEmpty
                        ? _profile!.displayNameEn[0].toUpperCase()
                        : 'C',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: kCitizenOrange,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l(_profile!.fullEn, _profile!.fullHi),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        context.l(
                          'Manage your information',
                          'अपनी जानकारी प्रबंधित करें',
                        ),
                        style: const TextStyle(fontSize: 12, color: kMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ProfileFieldGrid(
              fields: [
                ProfileField(
                  labelEn: 'Full Name (English)',
                  labelHi: 'पूरा नाम (अंग्रेज़ी)',
                  value: _profile!.fullEn,
                ),
                ProfileField(
                  labelEn: 'Full Name (Hindi)',
                  labelHi: 'पूरा नाम (हिंदी)',
                  value: _profile!.fullHi,
                ),
                ProfileField(
                  labelEn: "Father's Name (English)",
                  labelHi: 'पिता का नाम (अंग्रेज़ी)',
                  value: _profile!.fatherEn,
                ),
                ProfileField(
                  labelEn: "Father's Name (Hindi)",
                  labelHi: 'पिता का नाम (हिंदी)',
                  value: _profile!.fatherHi,
                ),
                ProfileField(
                  labelEn: 'Mobile',
                  labelHi: 'मोबाइल',
                  value: _profile!.mobile,
                  masked: true,
                ),
                ProfileField(
                  labelEn: 'Email',
                  labelHi: 'ईमेल',
                  value: _profile!.email,
                ),
                ProfileField(
                  labelEn: 'Jan Aadhaar ID',
                  labelHi: 'जन आधार ID',
                  value: _profile!.janAadhaar,
                  masked: true,
                ),
                ProfileField(
                  labelEn: 'Jan Member ID',
                  labelHi: 'जन सदस्य ID',
                  value: _profile!.janMember,
                  masked: true,
                ),
                ProfileField(
                  labelEn: 'District',
                  labelHi: 'जिला',
                  value: context.l(_profile!.district, _profile!.districtHi),
                ),
                ProfileField(
                  labelEn: 'SSO ID',
                  labelHi: 'SSO ID',
                  value: _profile!.sso,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
