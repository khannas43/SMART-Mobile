import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_rajasthan/i18n/app_locale.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    AppLocaleController.instance.setHindi(false, persist: false);
  });

  test('L and Lb switch with locale', () {
    AppLocaleController.instance.setHindi(false, persist: false);
    expect(L('Hello', 'नमस्ते'), 'Hello');
    expect(Lb('Scheme', 'योजना'), 'Scheme');

    AppLocaleController.instance.setHindi(true, persist: false);
    expect(L('Hello', 'नमस्ते'), 'नमस्ते');
    expect(Lb('Scheme', 'योजना'), 'योजना');
  });

  test('Lb falls back when preferred locale field is empty', () {
    AppLocaleController.instance.setHindi(true, persist: false);
    expect(Lb('English only', ''), 'English only');
    AppLocaleController.instance.setHindi(false, persist: false);
    expect(Lb('', 'हिंदी'), 'हिंदी');
  });

  test('consent and service status labels are bilingual', () {
    expect(AppLocaleService.consentStatusEn('PENDING'), 'Processing');
    expect(AppLocaleService.consentStatusHi('PENDING'), 'प्रक्रियाधीन');
    expect(AppLocaleService.serviceStatusEn('CONSENT'), 'Eligible');
    expect(AppLocaleService.serviceStatusHi('SUCCESS'), 'प्राप्त');
  });

  test('consentLanguage reflects active locale', () {
    AppLocaleController.instance.setHindi(false, persist: false);
    expect(AppLocaleService.instance.consentLanguage, 'English');
    AppLocaleController.instance.setHindi(true, persist: false);
    expect(AppLocaleService.instance.consentLanguage, 'Hindi');
  });

  test('formatDayMonthYear uses Hindi month abbreviations', () {
    final dt = DateTime(2026, 3, 15);
    AppLocaleController.instance.setHindi(false, persist: false);
    expect(AppLocaleService.formatDayMonthYear(dt), contains('Mar'));
    AppLocaleController.instance.setHindi(true, persist: false);
    expect(AppLocaleService.formatDayMonthYear(dt), contains('मार्च'));
  });
}
