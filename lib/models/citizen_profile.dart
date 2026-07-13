/// Maps `POST /smart/api/sso/getProfile` response to UI profile fields (activity 2.9).
class CitizenProfile {
  const CitizenProfile({
    required this.fullEn,
    required this.fullHi,
    required this.fatherEn,
    required this.fatherHi,
    required this.motherEn,
    required this.motherHi,
    required this.genderEn,
    required this.genderHi,
    required this.mobile,
    required this.email,
    required this.janAadhaar,
    required this.janMember,
    required this.district,
    required this.districtHi,
    required this.sso,
  });

  final String fullEn;
  final String fullHi;
  final String fatherEn;
  final String fatherHi;
  final String motherEn;
  final String motherHi;
  final String genderEn;
  final String genderHi;
  final String mobile;
  final String email;
  final String janAadhaar;
  final String janMember;
  final String district;
  final String districtHi;
  final String sso;

  String get displayNameEn => fullEn.isNotEmpty ? fullEn : 'Citizen';

  /// Builds from backend map (keys may vary in case — JDBC / Oracle).
  factory CitizenProfile.fromApiMap(
    Map<String, dynamic> raw, {
    String? ssoIdFallback,
  }) {
    String pick(List<String> keys, [String fallback = '']) {
      final value = _firstValue(raw, keys);
      return value ?? fallback;
    }

    final gender = pick(['GENDER', 'GENDER_EN', 'genderEn']);
    final genderHi = pick(['GENDER_HI', 'genderHi'], gender);

    final districtEn = pick(['DISTRICT_NAME_EN', 'DISTRICT', 'district']);
    final districtHi = pick(['DISTRICT_NAME_HI', 'districtHi'], districtEn);

    return CitizenProfile(
      fullEn: pick(['NAME_EN', 'nameEn', 'fullEn']),
      fullHi: pick(['NAME_HI', 'nameHi', 'fullHi']),
      fatherEn: pick(['FATHER_NAME_EN', 'fatherNameEn', 'fatherEn']),
      fatherHi: pick(['FATHER_NAME_HI', 'fatherNameHi', 'fatherHi']),
      motherEn: pick(['MOTHER_NAME_EN', 'motherNameEn', 'motherEn']),
      motherHi: pick(['MOTHER_NAME_HI', 'motherNameHi', 'motherHi']),
      genderEn: gender,
      genderHi: genderHi,
      mobile: pick(['MOBILE', 'MOBILE_NO', 'mobile']),
      email: pick(['EMAIL', 'email']),
      janAadhaar: pick(['JAN_AADHAAR_ID', 'JAN_AADHAAR', 'janAadhaar']),
      janMember: pick([
        'JAN_MEMBER_ID',
        'JAN_MEMBERID',
        'jan_member_id',
        'MEMBER_ID',
        'janMember',
      ]),
      district: districtEn,
      districtHi: districtHi,
      sso: pick(['SSO_ID', 'ssoId', 'sso'], ssoIdFallback ?? ''),
    );
  }

  /// Round-trip helper for callers expecting raw API keys.
  Map<String, dynamic> toApiMap() => {
        'NAME_EN': fullEn,
        'NAME_HI': fullHi,
        'FATHER_NAME_EN': fatherEn,
        'FATHER_NAME_HI': fatherHi,
        'MOTHER_NAME_EN': motherEn,
        'MOTHER_NAME_HI': motherHi,
        'GENDER': genderEn,
        'GENDER_HI': genderHi,
        'MOBILE': mobile,
        'EMAIL': email,
        'JAN_AADHAAR_ID': janAadhaar,
        'JAN_MEMBER_ID': janMember,
        'DISTRICT_NAME_EN': district,
        'DISTRICT_NAME_HI': districtHi,
        'SSO_ID': sso,
      };

  /// Shape expected by [ProfileScreen] and [MockApi.profile].
  Map<String, String> toUiMap() => {
        'fullEn': fullEn,
        'fullHi': fullHi.isNotEmpty ? fullHi : fullEn,
        'fatherEn': fatherEn,
        'fatherHi': fatherHi.isNotEmpty ? fatherHi : fatherEn,
        'motherEn': motherEn,
        'motherHi': motherHi.isNotEmpty ? motherHi : motherEn,
        'genderEn': genderEn,
        'genderHi': genderHi.isNotEmpty ? genderHi : genderEn,
        'mobile': mobile,
        'email': email,
        'janAadhaar': janAadhaar,
        'janMember': janMember,
        'district': district,
        'districtHi': districtHi.isNotEmpty ? districtHi : district,
        'sso': sso,
      };

  bool get isEmpty =>
      fullEn.isEmpty &&
      fullHi.isEmpty &&
      janMember.isEmpty &&
      janAadhaar.isEmpty;

  static String? _firstValue(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      for (final entry in raw.entries) {
        if (entry.key.toUpperCase() == key.toUpperCase()) {
          final text = entry.value?.toString().trim();
          if (text != null && text.isNotEmpty) return text;
        }
      }
    }
    return null;
  }
}
