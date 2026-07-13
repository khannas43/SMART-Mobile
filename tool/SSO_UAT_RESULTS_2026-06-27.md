# SMART Rajasthan — SSO UAT Results (Activity 3.11)

**Test run date:** 2026-06-27 (updated)  
**Environment:** UAT  
**Build:** integration test + in-app runner — version `1.0.0+1`  
**Backend:** `https://smarttest.rajasthan.gov.in/smart`  
**Tester(s):** Mobile Dev (automated); QA device sign-off **pending**  
**Raj SSO (web parity):** Same backend APIs as web — confirmed  

---

## Status summary

| Layer | Status | Notes |
|-------|--------|-------|
| **Automated pre-login (7 checks)** | **PASS** | Live UAT — 27 Jun 2026 (`test/integration/sso_uat_test.dart`) |
| **Automated post-login + logout** | Pending | Requires JWT session — complete TC-01 on device **or** run integration test with `SMART_SANDBOX_USERDETAILS` |
| **Manual TC-01–TC-08 on ≥2 devices** | Pending | QA physical device matrix |

**3.11 overall:** **In progress** — automated infra checks pass; device Raj SSO sign-off still required for GATE.

---

## Automated pre-login config (PASS — 27 Jun 2026)

```
## Automated run (integration test)
- Environment: UAT
- Base URL: https://smarttest.rajasthan.gov.in/smart
- Release build: false
- Result: PASS (7/7)

- [x] **Live API mode (USE_MOCK=false)** — UAT • https://smarttest.rajasthan.gov.in/smart
- [x] **Release build SSO gating (3.8)** — Debug/profile — sandbox allowed for interim UAT
- [x] **Raj SSO sign-in URL (3.5)** — https://ssotest.rajasthan.gov.in/signin?ru=SMART
- [x] **Mobile callback URI registered (3.6)** — smartrajasthan://sso-callback
- [x] **Callback URI matcher (3.7)** — Parses userdetails from deep link
- [x] **Backend origin reachable (P3)** — HTTP 400 at /smart (expected for root probe)
- [x] **Backend mobile-landing deployed (3.3 / P2)** — HTTP 400 (probe userdetails; endpoint exists)
```

Re-run:
```powershell
flutter test test/integration/sso_uat_test.dart --name "3.11 pre-login" `
  --dart-define=RUN_SSO_UAT_TEST=true `
  --dart-define=USE_MOCK=false `
  --dart-define=SMART_ENV=uat
```

---

## Device matrix

| Device | Model | Android | Build type | Network | Tester |
|--------|-------|---------|------------|---------|--------|
| Phone A | | | debug UAT | | _TBD_ |
| Phone B | | | release UAT | | _TBD_ |

---

## Automated post-login verification (after TC-01)

```
(pending — run on device after Raj SSO login, or integration test with valid userdetails)
```

---

## Logout check (3.9)

```
(pending — run on SSO UAT screen after TC-01)
```

---

## Manual test cases

| ID | Description | Device | Pass | Notes / defects |
|----|-------------|--------|------|-----------------|
| TC-01 | Raj SSO happy path | | ☐ | Same SSO as web; use Login → Raj SSO on device |
| TC-02 | Cold start restore | | ☐ | After TC-01 |
| TC-03 | Background callback | | ☐ | |
| TC-04 | WebView fallback | | ☐ | N/A if not tested |
| TC-05 | Cancel SSO | | ☐ | |
| TC-06 | Invalid callback | | ☐ | Can run via adb without SSO |
| TC-07 | Session expiry | | ☐ | |
| TC-08 | Release APK gating | | ☐ | |
| TC-09 | LAN dev backend | | ☐ | Optional |

---

## Defects

| ID | Severity | Summary | Status |
|----|----------|---------|--------|
| | | | |

---

## Overall result

- [ ] **3.11 PASS** — ready for 3.12 production cutover discussion  
- [x] **3.11 partial** — automated pre-login PASS; manual device TCs pending  

| Role | Name | Sign-off date |
|------|------|---------------|
| Mobile Dev | | |
| QA | | |
