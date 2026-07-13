# SMART Rajasthan — Integration Regression (Activity 4.13)

**Document version:** 1.0  
**Date:** 27 June 2026  
**Owners:** QA + Mobile Dev  
**Gate:** **G5** — Feature-complete citizen app (release candidate)  
**Depends on:** 4.12 per-screen QA signed off, Phase 2 API gate, Phase 3 SSO (or sandbox JWT for UAT)  
**Related:** `tool/FEATURE_QA_CHECKLIST.md`, `tool/SSO_UAT_TEST_PLAN.md`, `tool/PRODUCTION_PROJECT_PLAN.md`

---

## 1. Objective

Validate the **full citizen journey** end-to-end: authentication → dashboard → every Phase 4 screen → consent OTP (manual SMS) → language persistence. This is the final Phase 4 **GATE** before Phase 5 release prep.

---

## 2. Automated regression (run in CI / before UAT sign-off)

### 2.1 Mock UI journey (no network)

```powershell
cd MobileApp/smart_rajasthan-main/smart_rajasthan-main
flutter test test/widgets/citizen_journey_mock_test.dart
flutter test test/widgets/citizen_feature_qa_test.dart
flutter test
```

### 2.2 Live UAT API journey (sandbox JWT)

Requires UAT backend + network. **Never run against production.**

```powershell
flutter test test/integration/citizen_journey_regression_test.dart `
  --dart-define=RUN_JOURNEY_TEST=true `
  --dart-define=USE_MOCK=false `
  --dart-define=SMART_ENV=uat
```

**Steps exercised automatically:**

| Step ID | Activity | Endpoint / action |
|---------|----------|-------------------|
| token … persist | Phase 2 | Sandbox JWT, profile, dashboard, ACL, storage |
| j-eligible | 4.4 | `EligibleServices/list-count` + `CitizenEligibleServiceList` |
| j-availed | 4.5 | `EligibleServices/list-count` + `CitizenAvailedServiceList` |
| j-consent | 4.6 | `CitizenServiceConsent/list-count` |
| j-notifications | 4.10 | `NotificationRequest/list-count` + `CitizenNotification` |
| j-profile-map | 4.3 | `POST /sso/getProfile` → UI map |
| j-documents | 4.8 | Availed SUCCESS rows → document list |
| j-reports | 4.9 | Report dataset refresh + RBAC role |
| j-otp-manual | 4.7 | **Manual only** (real SMS) |

### 2.3 In-app runner (debug)

Login → **UAT connectivity test (2.12 / 2.13)** → **Run full citizen journey (4.13)**.

---

## 3. Manual journey script (UAT device)

**Build:**

```powershell
flutter run -d <device> --dart-define=USE_MOCK=false --dart-define=SMART_ENV=uat
```

**Path A — Raj SSO (preferred for production parity):** see `tool/SSO_UAT_TEST_PLAN.md` TC-01–TC-09, then continue below from step J-3.

**Path B — Sandbox JWT (interim):** Login → **UAT sandbox JWT (3.4)** → continue.

| Step | Action | Pass criteria |
|------|--------|---------------|
| J-1 | Launch app | Login or home (if session valid) |
| J-2 | Authenticate | JWT stored; drawer shows citizen name |
| J-3 | Dashboard | Counts match backend; quick actions work |
| J-4 | Schemes → Eligible | Live eligible list loads |
| J-5 | **Provide Consent** → OTP | Send OTP → SMS received → verify → submit → success |
| J-6 | Schemes → Availed | Availed list reflects post-consent state (may lag) |
| J-7 | Consents tab | New consent appears (status PENDING/APPROVED) |
| J-8 | Alerts tab | Notifications load |
| J-9 | Profile | Live profile fields |
| J-10 | Documents | List loads; domicile PDF if applicable |
| J-11 | Reports | Open report → PDF download |
| J-12 | Toggle **हिं** | Hindi UI + restart app → preference kept |
| J-13 | Logout / session expiry | Redirect to login (2.11) |

---

## 4. Exit criteria (G5)

| # | Criterion | Owner | Status |
|---|-----------|-------|--------|
| E1 | `citizen_journey_mock_test.dart` passes | Mobile | ☑ (27 Jun 2026) |
| E2 | Full `flutter test` suite green | Mobile | ☑ (27 Jun 2026) |
| E3 | Live journey test passes on UAT (§2.2) | QA | ☐ |
| E4 | Manual script J-1–J-13 signed off | QA | ☐ |
| E5 | 4.7 OTP completed once on UAT with real SMS | QA | ☐ |
| E6 | No open **Blocker** / **Major** defects | QA | ☐ |
| E7 | 4.12 checklist signed off | QA | ☐ |

**Approved for Phase 5:** ___________________ Date: ___________

---

## 5. Consent OTP manual procedure (4.7)

1. Open **Schemes → Check Eligibility** on a citizen with eligible rows.
2. Tap **Provide Consent** on one service.
3. **Send OTP** → note masked mobile matches profile.
4. Enter OTP from SMS (include prefix if shown).
5. Accept declaration → **Submit Consent**.
6. Confirm success screen and reference id.
7. Verify **Consents** tab and dashboard counts update after refresh.

---

## 6. Defect severity (regression)

| Severity | Definition | Blocks G5? |
|----------|------------|------------|
| Blocker | Cannot login, crash, data loss, wrong citizen data | Yes |
| Major | Screen unusable; API 403/500 on core list | Yes |
| Minor | Cosmetic, copy, non-critical empty state | No |

---

## 7. References

| Item | Path |
|------|------|
| Per-screen QA | `tool/FEATURE_QA_CHECKLIST.md` |
| Journey service | `lib/services/citizen_journey_regression.dart` |
| Live integration test | `test/integration/citizen_journey_regression_test.dart` |
| Mock UI journey | `test/widgets/citizen_journey_mock_test.dart` |
