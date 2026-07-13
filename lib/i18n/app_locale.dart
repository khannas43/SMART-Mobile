import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global locale controller — mirrors web `I18nProvider` state.
class AppLocaleController extends ChangeNotifier {
  AppLocaleController._();

  static final AppLocaleController instance = AppLocaleController._();

  bool _isHindi = false;

  bool get isHindi => _isHindi;

  /// Web uses `locale` key: `'en'` | `'hi'`.
  String get localeCode => _isHindi ? 'hi' : 'en';

  Locale get materialLocale =>
      _isHindi ? const Locale('hi', 'IN') : const Locale('en', 'IN');

  String get consentLanguage => _isHindi ? 'Hindi' : 'English';

  void setLocaleCode(String code, {bool persist = true}) {
    setHindi(code == 'hi', persist: persist);
  }

  void setHindi(bool hindi, {bool persist = true}) {
    if (_isHindi == hindi) return;
    _isHindi = hindi;
    notifyListeners();
    if (persist) {
      unawaited(AppLocaleService.instance._persistLocale(hindi));
    }
  }

  void toggle() => setHindi(!_isHindi);
}

/// Inherited locale scope — widgets that call [AppLocaleScope.watch] rebuild on change.
class AppLocaleScope extends InheritedNotifier<AppLocaleController> {
  const AppLocaleScope({
    required AppLocaleController super.notifier,
    required super.child,
    super.key,
  });

  static AppLocaleController watch(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    assert(scope != null, 'AppLocaleScope not found above $context');
    return scope!.notifier!;
  }

  static AppLocaleController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppLocaleScope>()
        ?.notifier;
  }
}

/// Context-based i18n — same pattern as web `useI18n().t()`.
extension AppLocaleContext on BuildContext {
  bool get isHindi => AppLocaleScope.watch(this).isHindi;

  String l(String en, String hi) => isHindi ? hi : en;

  String lb(String en, String hi) {
    final english = en.trim();
    final hindi = hi.trim();
    if (isHindi) return hindi.isNotEmpty ? hindi : english;
    return english.isNotEmpty ? english : hindi;
  }
}

/// Legacy global helper (no rebuild). Prefer [BuildContext.l] in widgets.
String L(String en, String hi) =>
    AppLocaleController.instance.isHindi ? hi : en;

/// Legacy global helper (no rebuild). Prefer [BuildContext.lb] in widgets.
String Lb(String en, String hi) {
  final english = en.trim();
  final hindi = hi.trim();
  if (AppLocaleController.instance.isHindi) {
    return hindi.isNotEmpty ? hindi : english;
  }
  return english.isNotEmpty ? english : hindi;
}

/// Persists locale across sessions (activity 4.11).
class AppLocaleService {
  AppLocaleService._();

  static final AppLocaleService instance = AppLocaleService._();

  static const _prefsKey = 'locale';
  static const _legacySecureKey = 'locale';
  static const _legacySecureKey2 = 'app_locale';

  AppLocaleController get controller => AppLocaleController.instance;

  bool get isHindi => controller.isHindi;

  Locale get materialLocale => controller.materialLocale;

  String get consentLanguage => controller.consentLanguage;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    var saved = prefs.getString(_prefsKey);

    if (saved == null) {
      const storage = FlutterSecureStorage();
      saved = await storage.read(key: _legacySecureKey);
      saved ??= await storage.read(key: _legacySecureKey2);
      if (saved != null) {
        unawaited(prefs.setString(_prefsKey, saved));
      }
    }

    if (saved == 'hi') {
      controller._isHindi = true;
    }
  }

  void setHindi(bool hindi) => controller.setHindi(hindi);

  void setLocaleCode(String code) => controller.setLocaleCode(code);

  void toggle() => controller.toggle();

  Future<void> _persistLocale(bool hindi) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, hindi ? 'hi' : 'en');
  }

  static String consentStatusEn(String raw) {
    switch (raw.toUpperCase()) {
      case 'APPROVED':
        return 'Approved';
      case 'PENDING':
        return 'Processing';
      case 'REJECTED':
        return 'Rejected';
      case 'SUBMITTED':
        return 'Submitted';
      default:
        return raw.isEmpty ? 'Submitted' : raw;
    }
  }

  static String consentStatusHi(String raw) {
    switch (raw.toUpperCase()) {
      case 'APPROVED':
        return 'स्वीकृत';
      case 'PENDING':
        return 'प्रक्रियाधीन';
      case 'REJECTED':
        return 'अस्वीकृत';
      case 'SUBMITTED':
        return 'जमा';
      default:
        return raw.isEmpty ? 'जमा' : raw;
    }
  }

  static String consentStatusLabel(String raw) =>
      L(consentStatusEn(raw), consentStatusHi(raw));

  static String serviceStatusEn(String raw) {
    switch (raw.toUpperCase()) {
      case 'SUCCESS':
        return 'Availed';
      case 'CONSENT':
        return 'Eligible';
      case 'INPROCESS':
      case 'IN_PROCESS':
        return 'In Process';
      case 'OPTOUT':
      case 'OPT_OUT':
        return 'Opt-Out';
      default:
        return raw.isEmpty ? '—' : raw;
    }
  }

  static String serviceStatusHi(String raw) {
    switch (raw.toUpperCase()) {
      case 'SUCCESS':
        return 'प्राप्त';
      case 'CONSENT':
        return 'पात्र';
      case 'INPROCESS':
      case 'IN_PROCESS':
        return 'प्रक्रियाधीन';
      case 'OPTOUT':
      case 'OPT_OUT':
        return 'ऑप्ट-आउट';
      default:
        return raw.isEmpty ? '—' : raw;
    }
  }

  static String serviceStatusLabel(String raw) =>
      L(serviceStatusEn(raw), serviceStatusHi(raw));

  static const _monthsEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const _monthsHi = [
    'जन', 'फर', 'मार्च', 'अप्रै', 'मई', 'जून',
    'जुल', 'अग', 'सित', 'अक्ट', 'नव', 'दिस',
  ];

  static String formatDayMonthYear(DateTime dt, {bool? hindi}) {
    final useHi = hindi ?? AppLocaleController.instance.isHindi;
    final months = useHi ? _monthsHi : _monthsEn;
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  static String formatDayMonthYearTime(DateTime dt, {bool? hindi}) {
    final useHi = hindi ?? AppLocaleController.instance.isHindi;
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = useHi
        ? (dt.hour >= 12 ? 'अपराह्न' : 'पूर्वाह्न')
        : (dt.hour >= 12 ? 'PM' : 'AM');
    return '${formatDayMonthYear(dt, hindi: useHi)}, '
        '${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }
}

String uiServiceName(BuildContext context, Map<String, String> row) =>
    context.lb(row['name'] ?? '', row['nameHi'] ?? row['name'] ?? '');

String uiServiceType(BuildContext context, Map<String, String> row) =>
    context.lb(
      row['typeEn'] ?? AppLocaleService.serviceStatusEn(row['type'] ?? ''),
      row['typeHi'] ?? AppLocaleService.serviceStatusHi(row['type'] ?? ''),
    );

String uiDeptLabel(BuildContext context, Map<String, String> row) =>
    context.lb(
      row['deptEn'] ?? row['dept'] ?? row['departmentName'] ?? '',
      row['deptHi'] ?? row['dept'] ?? row['departmentName'] ?? '',
    );

String uiConsentStatus(BuildContext context, Map<String, String> row) =>
    context.lb(row['status'] ?? '', row['statusHi'] ?? row['status'] ?? '');

String uiNotificationMessage(BuildContext context, Map<String, String> row) =>
    context.lb(row['msg'] ?? '', row['msgHi'] ?? row['msg'] ?? '');

String uiConsentServiceName(BuildContext context, Map<String, String> row) =>
    context.lb(
      row['service'] ?? '—',
      row['serviceHi'] ?? row['service'] ?? '—',
    );
