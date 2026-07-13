# SMART Rajasthan — Feature QA Checklist (Activity 4.12)

**Document version:** 1.0  
**Date:** 27 June 2026  
**Owners:** QA + Mobile Dev  
**Depends on:** Phase 4 citizen screens (4.2–4.11), Phase 2 API client + auth  
**Related:** `tool/PRODUCTION_PROJECT_PLAN.md`, `tool/SSO_UAT_TEST_PLAN.md`

---

## 1. Objective

Per-screen **feature QA pass** for the citizen app before integration regression (**4.13 GATE**). Each screen is verified in **mock mode** (fast UI regression) and **live UAT** (API contract + real data).

---

## 2. Automated smoke (run first)

```powershell
cd MobileApp/smart_rajasthan-main/smart_rajasthan-main
flutter test test/widgets/citizen_feature_qa_test.dart
```

| ID | Scope | Automated |
|----|--------|-----------|
| AUTO-01 | App launches (`SmartApp`) | `test/widget_test.dart` |
| AUTO-02 | All citizen tabs + documents/reports + consent OTP entry | `test/widgets/citizen_feature_qa_test.dart` |
| AUTO-03 | Models / i18n / nextquery contracts | `flutter test` (full suite) |

---

## 3. Build matrix

| Mode | Command | Use |
|------|---------|-----|
| Mock UI (default) | `flutter run -d <device>` | 4.12 UI pass, offline |
| Live UAT | `flutter run -d <device> --dart-define=USE_MOCK=false --dart-define=SMART_ENV=uat` | API + SSO/sandbox JWT |
| Live + LAN dev | add `--dart-define=SMART_API_HOST=http://10.0.2.2:8080` (emulator) | Local backend |

**Sign-in for live UAT:** Raj SSO WebView **or** Login → **UAT sandbox JWT (3.4)**.

---

## 4. Global checks (every screen)

| # | Check | Mock | Live UAT |
|---|--------|------|----------|
| G1 | EN / हिं toggle updates labels immediately | ☐ | ☐ |
| G2 | Header title matches active tab | ☐ | ☐ |
| G3 | Back from pushed routes returns to prior screen | ☐ | ☐ |
| G4 | Pull-to-refresh works (where implemented) | ☐ | ☐ |
| G5 | Error banner + **Retry** on API failure | N/A | ☐ |
| G6 | Empty state message when list is empty | ☐ | ☐ |
| G7 | No mock flash before live data (live only) | N/A | ☐ |
| G8 | 403 / session expiry → login redirect (2.11) | N/A | ☐ |

---

## 5. Per-screen test cases

### 4.2 — Dashboard (`MainShell` tab: Dashboard)

| ID | Steps | Expected | Mock | Live |
|----|--------|----------|------|------|
| D-01 | Open app → Dashboard | Welcome + display name; stat cards visible | ☐ | ☐ |
| D-02 | Verify counts | Eligible / Availed / In Process / Opt-Out / Consent cards | ☐ | ☐ |
| D-03 | Tap **Check Eligibility** quick action | Schemes tab → Eligible list | ☐ | ☐ |
| D-04 | Tap **View Documents** | Documents screen opens | ☐ | ☐ |
| D-05 | Tap **View Reports** / reports card | Reports list opens | ☐ | ☐ |
| D-06 | Pull to refresh | Counts reload (live: `/dashboard/citizenDashboardCount`) | ☐ | ☐ |

### 4.3 — Profile (tab: Profile)

| ID | Steps | Expected | Mock | Live |
|----|--------|----------|------|------|
| P-01 | Open Profile | Name, Jan Aadhaar, member ID, district | ☐ | ☐ |
| P-02 | Toggle Hindi | Hindi name / district when available | ☐ | ☐ |
| P-03 | Pull to refresh | Profile from `POST /sso/getProfile` | ☐ | ☐ |
| P-04 | Empty / error states | Retry works on network error | N/A | ☐ |

### 4.4 — Eligible services (Schemes → **Check Eligibility**)

| ID | Steps | Expected | Mock | Live |
|----|--------|----------|------|------|
| E-01 | Open Schemes → Eligible tab | Info banner + service cards | ☐ | ☐ |
| E-02 | Live load | Spinner → list from `EligibleServices/list-count` + `CitizenEligibleServiceList` | N/A | ☐ |
| E-03 | **View details** | Bottom sheet with service metadata | ☐ | ☐ |
| E-04 | Empty state | “No eligible services” when count = 0 | ☐ | ☐ |

### 4.5 — Availed services (Schemes → **Availed Benefits**)

| ID | Steps | Expected | Mock | Live |
|----|--------|----------|------|------|
| A-01 | Open Availed tab | Availed cards with date / status | ☐ | ☐ |
| A-02 | Sort by Date / Name | Order changes | ☐ | ☐ |
| A-03 | Tap card → **View details** | Detail sheet (district, block, parents) | ☐ | ☐ |
| A-04 | Live API | `CitizenAvailedServiceList` hook | N/A | ☐ |

### 4.6 — Consent list (tab: Consents)

| ID | Steps | Expected | Mock | Live |
|----|--------|----------|------|------|
| C-01 | Open Consents | List with service name, date, status badge | ☐ | ☐ |
| C-02 | Status badges | Approved / Processing / Rejected localized | ☐ | ☐ |
| C-03 | Pull to refresh | `CitizenServiceConsent/list-count` | ☐ | ☐ |

### 4.7 — Give consent + OTP (from eligible → **Provide Consent**)

| ID | Steps | Expected | Mock | Live |
|----|--------|----------|------|------|
| O-01 | Step 1 Send OTP | Mobile masked; timer starts | ☐ | ☐ |
| O-02 | Step 2 Verify | 6-digit OTP entry | ☐ | ☐ |
| O-03 | Mock OTP | `654321` advances flow | ☐ | N/A |
| O-04 | Step 3 Submit | Declaration checkbox + submit | ☐ | ☐ |
| O-05 | Live APIs | `sendConsentOTP` → `validateConsentOTP` → `EligibleServices/update` + `CitizenServiceConsent/create` | N/A | ☐ |
| O-06 | Success | Success screen; eligible list refreshes | ☐ | ☐ |
| O-07 | Resend OTP | Available after timer expires | ☐ | ☐ |

### 4.8 — Documents (Dashboard → View Documents)

| ID | Steps | Expected | Mock | Live |
|----|--------|----------|------|------|
| DOC-01 | Open documents | List of certificates / orders | ☐ | ☐ |
| DOC-02 | Domicile PDF row | Download action (live: emitra + open PDF) | ☐ | ☐ |
| DOC-03 | Error / empty | Retry + empty copy | ☐ | ☐ |

### 4.9 — Reports (Dashboard → View Reports)

| ID | Steps | Expected | Mock | Live |
|----|--------|----------|------|------|
| R-01 | Reports list | Role-scoped report cards | ☐ | ☐ |
| R-02 | Open report detail | Sections populate from cached API data | ☐ | ☐ |
| R-03 | Download PDF | PDF generated / opened | ☐ | ☐ |

### 4.10 — Notifications (tab: Alerts)

| ID | Steps | Expected | Mock | Live |
|----|--------|----------|------|------|
| N-01 | Open Alerts | Notification cards with date + mobile | ☐ | ☐ |
| N-02 | Channel icon | SMS / Email / WhatsApp styling | ☐ | ☐ |
| N-03 | Live API | `NotificationRequest/list-count` + `CitizenNotification` hook | N/A | ☐ |

### 4.11 — Language toggle

| ID | Steps | Expected | Mock | Live |
|----|--------|----------|------|------|
| L-01 | Toggle हिं | Nav, dashboard, schemes use Hindi | ☐ | ☐ |
| L-02 | API labels | Service names / status use `nameHi` / Hindi badges | ☐ | ☐ |
| L-03 | Persist | Kill app → preference restored | ☐ | ☐ |
| L-04 | Consent OTP live | `consentLanguage: Hindi` when toggled | N/A | ☐ |

---

## 6. Sign-off

| Screen | Tester | Mock date | Live UAT date | Notes |
|--------|--------|-----------|---------------|-------|
| 4.2 Dashboard | | | | |
| 4.3 Profile | | | | |
| 4.4 Eligible | | | | |
| 4.5 Availed | | | | |
| 4.6 Consents | | | | |
| 4.7 Consent OTP | | | | |
| 4.8 Documents | | | | |
| 4.9 Reports | | | | |
| 4.10 Notifications | | | | |
| 4.11 Language | | | | |
| **4.12 complete** | | | | |

**Gate to 4.13:** All rows signed off on **live UAT** (or documented waiver with owner approval). See `tool/INTEGRATION_REGRESSION_PLAN.md`.

---

## 7. Defect log (template)

| ID | Screen | Severity | Summary | Steps | Status |
|----|--------|----------|---------|-------|--------|
| | | Blocker / Major / Minor | | | Open / Fixed / Verified |

---

## 8. References

| Item | Path |
|------|------|
| Production plan | `tool/PRODUCTION_PROJECT_PLAN.md` |
| SSO UAT | `tool/SSO_UAT_TEST_PLAN.md` |
| Connectivity test | In-app **UAT connectivity test (2.12 / 2.13)** |
| Widget smoke tests | `test/widgets/citizen_feature_qa_test.dart` |
