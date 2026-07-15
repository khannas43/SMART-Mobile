import 'package:flutter/material.dart';

import '../app_globals.dart';
import '../app_theme.dart';
import '../i18n/app_locale.dart';
import '../screens/citizen/availed_services_screen.dart';
import '../screens/citizen/consent_screen.dart';

/// Cross-screen navigation helpers for the citizen panel.
class CitizenNavigation extends ChangeNotifier {
  CitizenNavigation._();

  static final CitizenNavigation instance = CitizenNavigation._();

  int? _pendingTab;
  ConsentSection? _pendingConsentSection;

  void goToDashboard() {
    _pendingTab = 0;
    notifyListeners();
  }

  void goToNotifications() {
    _pendingTab = 1;
    notifyListeners();
  }

  void goToUserManual() {
    _pendingTab = 2;
    notifyListeners();
  }

  /// Opens consent management as a pushed screen (web dashboard entry pattern).
  void goToProvideConsent() {
    _pendingConsentSection = ConsentSection.provide;
    _openConsentScreen();
  }

  void goToViewConsents() {
    _pendingConsentSection = ConsentSection.view;
    _openConsentScreen();
  }

  void goToAvailedServices() {
    final nav = gNavigatorKey.currentState;
    if (nav == null) {
      notifyListeners();
      return;
    }
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => const AvailedServicesScreen(),
      ),
    );
  }

  void _openConsentScreen() {
    final nav = gNavigatorKey.currentState;
    if (nav == null) {
      notifyListeners();
      return;
    }
    nav.push(
      MaterialPageRoute<void>(
        builder: (context) {
          AppLocaleScope.watch(context);
          return Scaffold(
            backgroundColor: kBg,
            appBar: AppBar(
              backgroundColor: Colors.white,
              foregroundColor: kText,
              elevation: 0,
              title: Text(
                context.l('Consent Management', 'सहमति प्रबंधन'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: Container(height: 3, color: kCitizenOrange),
              ),
            ),
            body: const CitizenConsentScreen(),
          );
        },
      ),
    );
  }

  int? consumePendingTab() {
    final tab = _pendingTab;
    _pendingTab = null;
    return tab;
  }

  ConsentSection? consumePendingConsentSection() {
    final section = _pendingConsentSection;
    _pendingConsentSection = null;
    return section;
  }
}

enum ConsentSection { provide, view }
