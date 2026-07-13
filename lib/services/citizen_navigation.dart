import 'package:flutter/foundation.dart';

/// Cross-tab navigation for citizen shell (dashboard ↔ consent).
class CitizenNavigation extends ChangeNotifier {
  CitizenNavigation._();

  static final CitizenNavigation instance = CitizenNavigation._();

  int? _pendingTab;
  ConsentSection? _pendingConsentSection;

  void goToDashboard() {
    _pendingTab = 0;
    notifyListeners();
  }

  void goToProvideConsent() {
    _pendingTab = 1;
    _pendingConsentSection = ConsentSection.provide;
    notifyListeners();
  }

  void goToViewConsents() {
    _pendingTab = 1;
    _pendingConsentSection = ConsentSection.view;
    notifyListeners();
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
