import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/models/citizen_profile.dart';

void main() {
  test('CitizenProfile maps backend NAME_EN fields to UI map', () {
    final profile = CitizenProfile.fromApiMap({
      'NAME_EN': 'Gaurav Goyal',
      'NAME_HI': 'गौरव गोयल',
      'FATHER_NAME_EN': 'Father Name',
      'MOTHER_NAME_EN': 'Mother Name',
      'GENDER': 'Male',
      'MOBILE': '****4037',
      'JAN_AADHAAR_ID': '****7835',
      'JAN_MEMBER_ID': '****4955',
      'DISTRICT_NAME_EN': 'Jaipur',
      'SSO_ID': 'GOURAV99GOYAL',
    });

    expect(profile.displayNameEn, 'Gaurav Goyal');
    expect(profile.toUiMap()['fullEn'], 'Gaurav Goyal');
    expect(profile.toUiMap()['janAadhaar'], '****7835');
    expect(profile.toApiMap()['NAME_EN'], 'Gaurav Goyal');
  });

  test('CitizenProfile reads keys case-insensitively', () {
    final profile = CitizenProfile.fromApiMap({
      'name_en': 'Test Citizen',
      'member_id': '12345',
    }, ssoIdFallback: 'test.sso');

    expect(profile.fullEn, 'Test Citizen');
    expect(profile.janMember, '12345');
    expect(profile.sso, 'test.sso');
  });

  test('CitizenProfile maps sanitized backend profile (activity 4.3)', () {
    final profile = CitizenProfile.fromApiMap({
      'NAME_EN': 'Gaurav Goyal',
      'NAME_HI': 'गौरव गोयल',
      'FATHER_NAME_EN': 'Father',
      'FATHER_NAME_HI': 'पिता',
      'MOTHER_NAME_EN': 'Mother',
      'MOTHER_NAME_HI': 'माता',
      'GENDER': 'Male',
      'MOBILE': '******4037',
      'EMAIL': 'citizen@example.com',
      'JAN_AADHAAR_ID': '****7835',
      'JAN_MEMBER_ID': '****4955',
      'DISTRICT_NAME_EN': 'Jaipur',
      'DISTRICT_NAME_HI': 'जयपुर',
      'SSO_ID': 'GOURAV99GOYAL',
    });

    final ui = profile.toUiMap();
    expect(ui['email'], 'citizen@example.com');
    expect(ui['districtHi'], 'जयपुर');
    expect(ui['mobile'], '******4037');
    expect(ui['janMember'], '****4955');
  });

  test('CitizenProfile accepts jan_member_id and MEMBER_ID aliases', () {
    final profile = CitizenProfile.fromApiMap({
      'NAME_EN': 'Alias Test',
      'jan_member_id': '998877',
    });

    expect(profile.janMember, '998877');

    final fromMemberId = CitizenProfile.fromApiMap({
      'NAME_EN': 'Web Field',
      'MEMBER_ID': '11223344',
    });
    expect(fromMemberId.janMember, '11223344');
  });
}
