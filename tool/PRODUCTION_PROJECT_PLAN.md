# SMART Rajasthan — Production Android App Project Plan

**Document version:** 1.10  
**Date:** 27 June 2026  
**Last status update:** 27 June 2026 (snapshot refresh — full test suite green)  
**Last backend review:** 27 June 2026 (`smart_backend_mono` latest)  
**Scope:** Production-quality Android citizen app (Flutter) integrated with `smart_backend_mono`  
**Out of scope:** iOS, macOS, web builds  

**Project roots**

| Component | Path |
|-----------|------|
| Mobile (Flutter) | `MobileApp/smart_rajasthan-main/smart_rajasthan-main/` |
| Backend API | `smart_backend_mono/` |
| Web reference (API contracts) | `smart_frontend/` |

**Backend base URL pattern**

| Environment | Base URL |
|-------------|----------|
| Local / LAN | `http://<host>:8080/smart` |
| UAT | `https://smarttest.rajasthan.gov.in/smart` |
| Production | `https://smart.rajasthan.gov.in/smart` |

---

## Backend review summary (latest `smart_backend_mono`)

Reviewed against current controllers and `smart_frontend` citizen flows. Key findings that affect the mobile plan:

| Area | Latest backend behaviour | Mobile impact |
|------|-------------------------|---------------|
| **Auth** | JWT via `Authorization: Bearer` or `jwt` cookie; `@PreAuthorize` ACL on `/api/nextquery/**` | Must send Bearer + `X-Current-Role: citizen` on all nextquery calls |
| **SSO (web parity)** | Raj SSO live on web (`signin?ru=SMART` → `/api/sso/landing`); same backend for all clients | Mobile uses **same** SSO APIs as web — see table below; JWT via Bearer not cookie |
| **SSO `/landing`** | Sets cookie + HTTP redirect (web); same validation as mobile | Mobile: `POST /landing` or `/sandboxlanding` + Set-Cookie fallback (**3.7a**), or `/mobile-landing` JSON (**3.3**) |
| **SSO `/sandboxlanding`** | With `Accept: application/json` returns `{ status, redirectUrl }` + `Set-Cookie` | UAT interim: extract JWT from cookie header if 3.3 delayed |
| **SSO `/getSandBoxToken`** | Returns `{ "token": "<jwt>" }` | **Primary UAT/dev auth** for Phase 4 (mirror `SsoSandbox.tsx`) |
| **SSO `/signout`** | `POST` with `{ "userdetails": "..." }` | Wire mobile logout (task 3.9) |
| **SSO `/family-list`** | Exists but uses hardcoded member ID — **not production-ready** | Do **not** integrate until backend fixes |
| **JWT claims** | Now includes `panelTypes`, `roleDetails`, `levelId` (in addition to `ssoId`, `smUserId`, `currentSrole`) | Extend JWT decode in task 2.7 |
| **Citizen consent OTP** | **`CitizenConsentController`** — not raw `/open/otp-transaction` from mobile | Use `/api/CitizenConsent/sendConsentOTP` + `validateConsentOTP` (matches web) |
| **Consent completion** | After OTP: `EligibleServices/update` + `CitizenServiceConsent/create` via nextquery | Add to task 4.7 (see `SchemeVerificationModal.tsx`) |
| **Eligible list** | `POST /api/nextquery/EligibleServices/list-count` | Same model for eligible tab |
| **Availed list** | Same endpoint + filter `executeActionName: "CitizenAvailedServiceList"` | Update task 4.5 |
| **Consent list** | `POST /api/nextquery/CitizenServiceConsent/list-count` | Update task 4.6 |
| **Notifications** | `POST /api/nextquery/NotificationRequest/list-count` | Update task 4.10 (not SMS send API) |
| **Documents / certs** | `POST /api/emitra/token` + domicile PDF (`/api/open/...`) | Update task 4.8 |
| **Security** | `/api/CitizenConsent/**`, `/api/dashboard/**`, `/api/nextquery/**` require authenticated JWT | `/api/open/**` and `/api/sso/**` are permitAll but citizen flows need JWT |

**Mobile SSO = web SSO APIs (confirmed 27 June 2026):**

| Flow | Web (`smart_frontend`) | Mobile (Flutter) |
|------|------------------------|------------------|
| Raj SSO entry | `NEXT_PUBLIC_RAJSSO_URL` → `signin?ru=SMART` | `SsoConfig.rajSsoSignInUri()` — same URL |
| UAT dev token | `SsoSandbox.tsx` → `getSandBoxToken` | `SandboxAuthService` — same path |
| UAT landing | `sandboxlanding` POST | `SsoLandingService` — same path |
| Prod landing | Browser → `/landing` (cookie) | `/landing` or `/mobile-landing` (Bearer) — same backend validation |
| Profile | `Profile.tsx` → `getProfile` | `SmartApiService.getProfile()` — same path + body |
| Dashboard | `citizen/page.tsx` → `citizenDashboardCount` | `fetchCitizenDashboardCounts()` — same form POST |
| Logout | `LoginProfile.tsx` → `signout` | `RajSsoAuthService.signOut()` — same body `{ userdetails }` |

**Only difference:** web stores JWT in cookie; mobile stores in secure storage and sends `Authorization: Bearer`. No separate mobile SSO backend.

**Web files to mirror (source of truth for contracts):**

- `smart_frontend/components/SsoSandbox.tsx` — sandbox token + landing (UAT)
- `smart_frontend/components/LoginProfile.tsx` — signout
- `smart_frontend/components/SchemeVerificationModal.tsx` — consent OTP + post-consent create
- `smart_frontend/components/OTPVerificationModal.tsx` — consent OTP calls
- `smart_frontend/components/AvailedServiceListCard.tsx` — availed list + certificate
- `smart_frontend/app/(citizen)/citizen/page.tsx` — dashboard counts
- `smart_frontend/utils/api-fetcher.ts` — nextquery + headers

---

**Build outputs (Flutter CLI — Android Studio not required for builds)**  
**Full guide:** [`tool/BUILD.md`](BUILD.md) · Project entry: [`README.md`](../README.md)

| Artifact | Command | Output path |
|----------|---------|-------------|
| Release APK | `flutter build apk --release` | `build/app/outputs/flutter-apk/app-release.apk` |
| Release AAB (Play Store) | `flutter build appbundle --release` | `build/app/outputs/bundle/release/app-release.aab` |

---

## Legend — parallel execution & status

| Symbol | Meaning |
|--------|---------|
| **SEQ** | Must complete before the next dependent task starts |
| **∥** | Can run **in parallel** with the linked task(s) |
| **GATE** | Hard milestone — downstream work blocked until passed |

| Status | Meaning |
|--------|---------|
| **Done** | Complete (implementation and local verification) |
| **In progress** | Started — partial work, QA pending, or awaiting sign-off |
| **Not started** | Not yet begun |
| **Blocked** | Waiting on external dependency (SSO team, backend, audit, etc.) |
| **N/A** | Optional or deferred for v1 |

---

## Team roles (recommended)

| Role | Responsibilities |
|------|------------------|
| **Mobile Dev** | Flutter app, API client, UI integration, Android build |
| **Backend Dev** | Mobile SSO callback, API fixes, UAT/prod config |
| **SSO Coordinator** | Raj SSO redirect URI whitelist, prod sign-off |
| **QA** | Test plans, device matrix, UAT/prod regression |
| **Release Owner** | Keystore custody, Play Console / MDM, compliance |

**Minimum viable team:** 1 Mobile Dev + part-time Backend Dev + part-time QA  
**Recommended for 8–10 week target:** 1 Mobile Dev + 1 Backend Dev + SSO Coordinator + QA  

---

## Phase summary & timeline

| Phase | Name | Duration (1 mobile dev) | Duration (recommended team) | Status |
|-------|------|-------------------------|-----------------------------|--------|
| **1** | Android build pipeline & project baseline | 0.5–2 days | 0.5–1 day | **Done** — GATE passed |
| **2** | API foundation & secure auth storage | 3–5 days | 3–4 days | **In progress** — **2.13** open; GATE not passed |
| **3** | Rajasthan SSO (mobile production flow) | 1–3 weeks | 1–2 weeks | **In progress** — API parity with web **done**; **3.11** device QA + **3.12** sign-off pending |
| **4** | Screen integration (real backend data) | 3–6 weeks | 2–4 weeks | **In progress** — screens wired; **4.13** / SMS E2E QA sign-off pending |
| **5** | Production release & rollout | 1–2 weeks | 1–2 weeks | **Not started** — early prep only (5.1, 5.2, 5.5) |
| **Total** | End-to-end production app | **10–14 weeks** | **8–10 weeks** | — |

### Current snapshot (27 June 2026)

**Test suite:** `116 passed`, `6 skipped`, `0 failed` — `flutter test` 27 June 2026 (**All tests passed**)  
- **Skipped (6):** live UAT/prod integration tests — run with `--dart-define` flags per each test file: `citizen_acl_verification` (1), `citizen_journey_regression` (1), `sso_prod_cutover` (1), `sso_uat` (2), `uat_connectivity` (1)

| | Done | In progress | Not started / Blocked |
|---|------|-------------|------------------------|
| **Phase 1** | 12 / 12 | — | — |
| **Phase 2** | 13 / 14 | **2.13** (mobile ACL runner; **Backend UAT sign-off pending**) | — |
| **Phase 3** | 12 / 12 | **3.11** (device UAT with real Raj SSO), **3.12** (prod cutover — manual sign-off pending) | — |
| **Phase 4** | 13 / 14 (+ 4.0 N/A) | **4.13** (manual journey + SMS OTP QA) | — |
| **Phase 5** | 0 / 14 | **5.1**, **5.2**, **5.5** | 5.3–5.4, 5.6–5.14 |

**Open dependency gates:** G7 (**2.13** ACL) · G4 (**3.12** prod SSO sign-off) · G5 (**4.13** QA sign-off) · G6 (rollout)

**Next critical path:** **2.13** Backend ACL → **3.11** device SSO UAT (same APIs as web) → **3.12** prod cutover → Phase 5 rollout

**QA / regression artifacts**

| Activity | Document / runner |
|----------|-------------------|
| 2.12 UAT connectivity | `lib/services/uat_connectivity_test.dart`, `test/integration/uat_connectivity_test.dart` |
| 2.13 CITIZEN ACL | `tool/CITIZEN_ACL_VERIFICATION.md`, `test/integration/citizen_acl_verification_test.dart` |
| 3.11 SSO UAT | `tool/SSO_UAT_TEST_PLAN.md`, `lib/screens/sso_uat_screen.dart`, `test/integration/sso_uat_test.dart` |
| 3.12 Prod cutover | `tool/SSO_PROD_CUTOVER_CHECKLIST.md`, `lib/screens/sso_prod_cutover_screen.dart`, `test/integration/sso_prod_cutover_test.dart` |
| 4.12 Per-screen QA | `tool/FEATURE_QA_CHECKLIST.md`, `test/widgets/citizen_feature_qa_test.dart` |
| 4.13 Full journey | `tool/INTEGRATION_REGRESSION_PLAN.md`, `test/widgets/citizen_journey_mock_test.dart`, `test/integration/citizen_journey_regression_test.dart` |

---

## Phase 1 — Android build pipeline & project baseline

**Goal:** Verified Android toolchain, runnable app, release build path configured.  
**Duration:** 0.5–2 days  

### Activities

| ID | Activity | Owner | Duration | Depends on | Parallel | Status |
|----|----------|-------|----------|------------|----------|--------|
| 1.1 | Run `flutter doctor`; fix SDK / license issues | Mobile | 2–4 hrs | — | **∥ 1.2** | Done |
| 1.2 | Confirm project path & `flutter pub get` | Mobile | 30 min | — | **∥ 1.1** | Done |
| 1.3 | Run app on Android emulator / physical device (`flutter run -d android`) | Mobile | 1–2 hrs | 1.1, 1.2 | SEQ | Done |
| 1.4 | Add `INTERNET` permission to `AndroidManifest.xml` (required before API work) | Mobile | 30 min | 1.3 | **∥ 1.5, 1.6** | Done |
| 1.5 | Review / finalize `applicationId` (`smart.rajasthan.gov.in`) | Mobile + Release | 1–4 hrs | — | **∥ 1.4, 1.6, 2.1** | Done |
| 1.6 | Generate app launcher icons (`dart run flutter_launcher_icons`) | Mobile | 30 min | — | **∥ 1.4, 1.5** | Done |
| 1.7 | Create **release keystore** (keytool) & document custody | Release Owner | 2–4 hrs | — | **∥ 1.4–1.6, 2.1, 5.1** | Done |
| 1.8 | Configure release signing in `android/app/build.gradle.kts` | Mobile | 2–4 hrs | 1.7 | **∥ 2.1** (after 1.7 exists) | Done |
| 1.9 | Build debug APK: `flutter build apk --debug` | Mobile | 30 min | 1.3 | SEQ | Done |
| 1.10 | Build release APK: `flutter build apk --release` | Mobile | 30 min | 1.8 | SEQ | Done |
| 1.11 | Build release AAB: `flutter build appbundle --release` | Mobile | 30 min | 1.8 | **∥ 1.10** | Done |
| 1.12 | Document build commands in team wiki / README | Mobile | 1 hr | 1.10 | **∥ Phase 2+** | Done — [`README.md`](../README.md), [`tool/BUILD.md`](BUILD.md) |

### Phase 1 GATE

- [x] App launches on Android device without errors  
- [x] Release APK and AAB build successfully with **production keystore** (not debug signing)  

---

## Phase 2 — API foundation & secure auth storage

**Goal:** Reusable HTTP client, environment config, JWT persistence, first live API calls.  
**Duration:** 3–5 days  
**Can start:** **∥ Phase 1** (from day 1, tasks 1.1–1.2 done)  

### Activities

| ID | Activity | Owner | Duration | Depends on | Parallel | Status |
|----|----------|-------|----------|------------|----------|--------|
| 2.1 | Add dependencies: `dio`, `flutter_secure_storage` (+ optional `json_serializable`) | Mobile | 2 hrs | 1.2 | **∥ 1.4–1.8, 3.1** | Done |
| 2.2 | Create `lib/config/env.dart` — dev / UAT / prod base URLs (`--dart-define`) | Mobile | 2–4 hrs | 2.1 | SEQ | Done |
| 2.3 | Create `SmartApiClient` — base URL `/smart`, timeouts, interceptors | Mobile | 4–8 hrs | 2.2 | SEQ | Done |
| 2.4 | Implement JWT attach: `Authorization: Bearer <token>` | Mobile | 2–4 hrs | 2.3 | SEQ | Done |
| 2.5 | Implement role headers (match web): `X-Current-Role: citizen`, etc. | Mobile | 2–4 hrs | 2.4 | SEQ | Done |
| 2.5a | Create `NextQueryClient` wrapper — POST JSON body `{ model, fields, filters, page, size, sorting }` | Mobile | 4–8 hrs | 2.5 | SEQ | Done |
| 2.6 | Create `AuthService` — save/load/clear token via secure storage | Mobile | 4–8 hrs | 2.1 | **∥ 2.3–2.5a** | Done |
| 2.7 | JWT decode utility (`ssoId`, `smUserId`, `Name`, `currentSrole`, `panelTypes`, `jfId`) | Mobile | 2–4 hrs | 2.6 | SEQ | Done |
| 2.8 | Introduce `SmartApi` interface; keep `MockApi` behind feature flag | Mobile | 4–8 hrs | 2.3 | **∥ 2.6–2.7** | Done |
| 2.9 | Integrate `POST /smart/api/sso/getProfile` | Mobile | 4–8 hrs | 2.4, token available | **∥ 2.10** (sandbox token) | Done |
| 2.10 | Integrate `POST /smart/api/dashboard/citizenDashboardCount` (form: `ssoId`, `userId`) | Mobile | 4–8 hrs | 2.4, token available | **∥ 2.9** | Done |
| 2.11 | Global error handling (401 → logout, 403 ACL → user message, network retry) | Mobile | 4–8 hrs | 2.9 | **∥ 4.x screen work** | Done |
| 2.12 | UAT connectivity test (emulator `10.0.2.2:8080` vs device LAN IP) | Mobile + QA | 2–4 hrs | 2.9 | SEQ | Done |
| 2.13 | Verify CITIZEN ACL permissions on nextquery models (`EligibleServices`, `CitizenServiceConsent`, `NotificationRequest`) | Mobile + Backend | 2–4 hrs | 2.5a, 3.4 | **∥ Phase 4** | In progress — mobile runner only; **Backend UAT sign-off pending** |
| 2.14 | Unit tests for API client, nextquery wrapper & auth service | Mobile | 4–8 hrs | 2.11 | **∥ Phase 4** | Done |

### Phase 2 GATE

- [x] App calls UAT backend with sandbox JWT (`getSandBoxToken`)  
- [x] Profile and dashboard count return real data  
- [x] Token persists across app restarts  
- [ ] Nextquery call succeeds with Bearer + `X-Current-Role` (no 403 ACL errors) — **blocked on 2.13 Backend ACL sign-off**

### Phase 2 parallel map

```
1.1–1.2 ──► 2.1 ──► 2.2 ──► 2.3 ──► 2.4 ──► 2.5 ──► 2.5a ──► 2.9 ∥ 2.10
                └──► 2.6 ──► 2.7
                └──► 2.8 (mock/live toggle)
                └──► 2.13 (ACL verify, ∥ Phase 4)
3.1–3.3 (SSO paperwork) runs ∥ entire Phase 2
1.7–1.8 (keystore) runs ∥ Phase 2
```

---

## Phase 3 — Rajasthan SSO (mobile production flow)

**Goal:** Real Raj SSO login on Android; JWT obtained without browser cookies.  
**Duration:** 1–3 weeks  
**Critical path for production login**  

### Activities

| ID | Activity | Owner | Duration | Depends on | Parallel | Status |
|----|----------|-------|----------|------------|----------|--------|
| 3.1 | Define mobile SSO approach (Custom Tab / WebView + deep link) | Mobile + Backend | 4–8 hrs | — | **∥ Phase 1, 2** | Done |
| 3.2 | Register Android redirect URI with Raj SSO team (e.g. `smartrajasthan://sso-callback`) | SSO Coordinator + Backend | 1–2 days (in-repo) | 3.1 | **∥ Phase 2, 4 (sandbox)** | Done — `SSO_3.2_COMPLETION.md`, `/landing?client=mobile`; Raj SSO POST config optional follow-up |
| 3.3 | Backend: add `/api/sso/mobile-landing` (or extend `/landing`) returning `{ token, currentSrole, redirectPath }` in JSON body | Backend | 2–5 days | 3.1 | **∥ 3.4** | Done |
| 3.4 | UAT: integrate `POST /smart/api/sso/getSandBoxToken?userdetails=...` → store `{ token }` | Mobile | 1–2 days | 2.6 | **∥ 3.2, 3.3, Phase 4** | Done |
| 3.5 | Implement SSO WebView / Chrome Custom Tab login screen | Mobile | 3–5 days | 3.1 | **∥ 3.3** (use sandbox until 3.3 ready) | Done |
| 3.6 | Configure Android deep link intent-filter in `AndroidManifest.xml` | Mobile | 2–4 hrs | 3.5 | SEQ | Done |
| 3.7 | Parse SSO callback → exchange `userdetails` via `/smart/api/sso/landing` (prod) or `/sandboxlanding` (UAT) | Mobile | 1–2 days | 3.3, 3.5 | SEQ | Done |
| 3.7a | Interim UAT fallback: parse JWT from `Set-Cookie` on `/sandboxlanding` if 3.3 not ready | Mobile | 4–8 hrs | 3.7 | **∥ 3.8** | Done |
| 3.8 | Store JWT in secure storage; remove mock login navigation in release builds | Mobile | 4–8 hrs | 3.7 or 3.4 | SEQ | Done |
| 3.9 | Logout: clear token + `POST /smart/api/sso/signout` with `{ userdetails }` | Mobile | 4–8 hrs | 3.8 | **∥ 3.10** | Done |
| 3.10 | Session expiry handling (401 refresh → login screen) | Mobile | 4–8 hrs | 2.11, 3.8 | **∥ 3.9** | Done |
| 3.11 | UAT end-to-end SSO test on physical devices | Mobile + QA | 2–3 days | 3.8 | SEQ | In progress — **automated pre-login PASS** (7/7 live UAT); manual TC-01–TC-08 on ≥2 devices pending (`SSO_UAT_RESULTS_2026-06-27.md`, `test/integration/sso_uat_test.dart`) |
| 3.12 | Production SSO cutover & sign-off | QA + Mobile | 2–3 days | 3.11 | **GATE** | In progress — kickoff `SSO_PROD_CUTOVER_RESULTS_2026-06-27.md`; PC-01–PC-08 pending |

### Phase 3 GATE

- [ ] User logs in via Raj SSO on Android (UAT + Production) — **same SSO as web; mobile code ready; 3.11 / 3.12 device sign-off pending**
- [x] JWT stored securely; no mock login path in release builds (3.8)
- [x] Logout and session expiry implemented (3.9, 3.10) — **verify on device in 3.11 / 3.12**

### Phase 3 parallel map

```
3.1 ──► 3.3 (backend JSON token) ∥ 3.4 (sandbox token) ──► Phase 4 screen work
3.5–3.10 (mobile SSO UI + JWT lifecycle) — Done
3.2 (mobile redirect + registration package) — Done
3.11 (device UAT) ──► 3.12 (prod cutover GATE)
```

**Important:** Raj SSO is **already live on web** — mobile uses the same `POST /api/sso/landing` with `client=mobile` for Custom Tab deep-link return (3.2). Production release **requires 3.11 + 3.12** device sign-off.

---

## Phase 4 — Screen integration (production data)

**Goal:** Replace all `MockApi` usage with real backend calls; production UX quality.  
**Duration:** 3–6 weeks (2–4 weeks with 2 mobile devs on split screens)  
**Can start:** After Phase 2 GATE (using sandbox token); real login after Phase 3 GATE  

### Activities — shared foundation

| ID | Activity | Owner | Duration | Depends on | Parallel | Status |
|----|----------|-------|----------|------------|----------|--------|
| 4.0 | Split `main.dart` into feature modules (optional but recommended) | Mobile | 2–3 days | 2.8 | **∥ 4.1–4.8** | N/A |
| 4.0a | Add loading / empty / error states for all data screens | Mobile | 2–3 days | 2.11 | **∥ 4.1–4.8** | Done — `lib/widgets/data_screen_states.dart`; wired on dashboard, consents, documents, reports, notifications, profile |
| 4.0b | Hindi labels from API where available (`nameHi`, etc.) | Mobile | 1–2 days | 4.1+ | **∥ all 4.x** | Done — `lib/i18n/app_locale.dart`, `uiDeptLabel` on consents/documents, `CitizenDocument.deptHi`, profile `CITIZEN` badge bilingual |

### Activities — by feature (highly parallel after 4.0)

| ID | Activity | Backend endpoint(s) | Owner | Duration | Depends on | Parallel | Status |
|----|----------|---------------------|-------|----------|------------|----------|--------|
| **4.1** | **Login screen** — wire to SSO (Phase 3) or sandbox | `/smart/api/sso/*` | Mobile | 2–3 days | 3.8 or 3.4 | **GATE for prod** | Done — `lib/screens/login_screen.dart`; Raj SSO + sandbox; **prod login gated on 3.12** |
| **4.2** | **Dashboard** — counts & navigation | `/smart/api/dashboard/citizenDashboardCount` | Mobile | 2–3 days | 2.10 | **∥ 4.3–4.8** | Done |
| **4.3** | **Profile** — personal & linked IDs | `/smart/api/sso/getProfile` | Mobile | 2–3 days | 2.9 | **∥ 4.2, 4.4–4.8** | Done |
| **4.4** | **Eligible schemes** — list & detail | `POST /api/nextquery/EligibleServices/list-count` (model: `EligibleServices`) | Mobile | 4–6 days | 2.5a | **∥ 4.2, 4.3, 4.5–4.8** | Done |
| **4.5** | **Availed schemes** — list, sort, detail | Same as 4.4 + filter `executeActionName: "CitizenAvailedServiceList"` | Mobile | 3–5 days | 2.5a | **∥ 4.2–4.4, 4.6–4.8** | Done |
| **4.6** | **Consent list** (view submitted consents) | `POST /api/nextquery/CitizenServiceConsent/list-count` | Mobile | 3–4 days | 2.5a | **∥ 4.2–4.5, 4.7, 4.8** | Done |
| **4.7** | **Give consent + OTP** — send OTP, validate, record consent | See consent flow below | Mobile | 5–8 days | 2.5a | **∥ 4.2–4.6, 4.8** | Done |
| **4.8** | **Documents / certificates** — view & download PDF | `POST /api/emitra/token`; `GET /api/open/domicile-certificate/pdf`; `GET /api/service/s3/preview/{folder}/{file}` | Mobile | 4–6 days | 2.5a | **∥ 4.2–4.7** | Done |
| **4.9** | **Reports** — RBAC-scoped list & PDF download | Align with web citizen reports (nextquery + PDF) | Mobile | 4–7 days | 2.5a, 2.7 | **∥ 4.2–4.8** | Done |
| **4.10** | **Notifications** | `POST /api/nextquery/NotificationRequest/list-count` | Mobile | 3–5 days | 2.5a | **∥ 4.2–4.9** | Done |
| **4.11** | **Language toggle** — ensure API + UI strings consistent | — | Mobile | 1–2 days | 4.2+ | **∥ 4.2–4.10** | Done |
| **4.12** | Feature QA pass (per screen) | — | QA | 3–5 days | 4.2+ | **∥ ongoing** | Done |
| **4.13** | Integration regression (full citizen journey) | — | QA + Mobile | 3–5 days | 4.1–4.10 | **GATE** | In progress — E1/E2 automated green; manual J-1–J-13 + SMS OTP pending |

### Task 4.7 — Citizen consent flow (matches latest backend + web)

Step-by-step (mirror `SchemeVerificationModal.tsx`):

| Step | Action | Endpoint |
|------|--------|----------|
| 1 | Send OTP for eligible service record | `GET /smart/api/CitizenConsent/sendConsentOTP?consentId={eligibleServiceId}` |
| 2 | Validate OTP (store `transactionId` from step 1 response as `tid`) | `GET /smart/api/CitizenConsent/validateConsentOTP?tid={tid}&otp={otp}` |
| 3 | Mark service availed | `POST /smart/api/nextquery/EligibleServices/update/id/{id}` — body: `{ model, data: { status: "SUCCESS" } }` |
| 4 | Create consent record | `POST /smart/api/nextquery/CitizenServiceConsent/create` — body: `{ model, data: { ... } }` |

**Notes:**
- `CitizenConsentController` internally uses `OtpTransactionService` — mobile should **not** call `/api/open/otp-transaction/*` directly for this flow.
- All steps require JWT (`Authorization: Bearer`) except where backend explicitly permitAll.
- OTP prefix flow: if backend returns `otpPrefix`, pass it to `validateConsentOTP` as query param.
- Low-level OTP API docs remain in `smart_backend_mono/src/main/resources/document/otpTransactionAPI.txt` for reference only.

### Phase 4 GATE

- [x] All in-scope citizen screens use live APIs (no mock data in release) — **release build forces live API**
- [ ] Consent OTP E2E via `/CitizenConsent/*` on UAT with real SMS
- [ ] QA sign-off on citizen user journey (`INTEGRATION_REGRESSION_PLAN.md` E3–E7)

### Phase 4 parallel map (2 mobile devs)

```
Dev A: 4.2 Dashboard ──► 4.4 Eligible ──► 4.7 Consent/OTP
Dev B: 4.3 Profile  ──► 4.5 Availed  ──► 4.8 Documents ──► 4.9 Reports
Both:  4.10 Notifications (last week)
QA:    4.12 continuous ∥ 4.13 final GATE
```

---

## Phase 5 — Production release & rollout

**Goal:** Signed AAB, compliance, UAT/prod validation, distribution.  
**Duration:** 1–2 weeks (final gate); **prep tasks start Week 1**  

### Activities

| ID | Activity | Owner | Duration | Depends on | Parallel | Status |
|----|----------|-------|----------|------------|----------|--------|
| 5.1 | Release keystore custody & backup procedure | Release Owner | 2–4 hrs | 1.7 | **∥ Phase 2–4** (start Week 1) | In progress |
| 5.2 | Finalize `applicationId` & version scheme (`versionCode` / `versionName`) | Mobile + Release | 2–4 hrs | 1.5 | **∥ Phase 2–4** | In progress |
| 5.3 | Network security config (HTTPS only for prod) | Mobile | 2–4 hrs | 2.2 | **∥ Phase 3–4** | Not started |
| 5.4 | ProGuard / R8 rules (if required by plugins) | Mobile | 1–2 days | 4.0 | **∥ Phase 4** | Not started |
| 5.5 | Remove debug flags, sandbox endpoints, mock login from release build | Mobile | 4–8 hrs | 4.13, 3.12 | SEQ | In progress |
| 5.6 | Privacy policy & Play Console Data Safety form | Release Owner | 1–2 days | — | **∥ Phase 2–4** | Not started |
| 5.7 | Play Console app listing (screenshots, description EN/HI) | Mobile + Release | 1–2 days | 4.2+ | **∥ Phase 4** | Not started |
| 5.8 | Internal test track upload (AAB) | Release Owner | 2–4 hrs | 1.11, 5.5 | SEQ | Not started |
| 5.9 | Device matrix testing (Android 8–14, low/high RAM) | QA | 3–5 days | 5.8 | **∥ 5.10** | Not started |
| 5.10 | Production smoke test (SSO + dashboard + consent OTP) | QA + Mobile | 2–3 days | 3.12, 4.13 | **∥ 5.9** | Not started |
| 5.11 | Security / compliance review (gov audit if required) | Release Owner | 3–10 days | 5.10 | **∥ 5.12 prep** | Not started |
| 5.12 | Production AAB build & signed artifact archive | Mobile | 2–4 hrs | 5.5, 5.11 | SEQ | Not started |
| 5.13 | Rollout: Play Store production or approved MDM | Release Owner | 1–3 days | 5.12 | **GATE — project complete** | Not started |
| 5.14 | Post-release monitoring plan (crash analytics, API errors) | Mobile + Backend | 1–2 days | 5.13 | SEQ | Not started |

### Phase 5 GATE (project complete)

- [ ] Signed production AAB deployed to approved channel  
- [ ] Prod SSO + core citizen flows verified  
- [ ] Compliance / security sign-off (if applicable)  

### Phase 5 parallel map

```
Week 1–6 (early prep, parallel):
  5.1 ∥ 5.2 ∥ 5.3 ∥ 5.6 ∥ 5.7

Week 7–10 (after Phase 4 GATE):
  5.5 ──► 5.8 ──► 5.9 ∥ 5.10 ──► 5.11 ──► 5.12 ──► 5.13
```

---

## Master schedule — 10-week plan (recommended team)

| Week | Phase | Primary activities | Parallel activities |
|------|-------|-------------------|---------------------|
| **1** | 1 + 2 | Build pipeline, keystore, API client, env config | 3.1 SSO design; 5.1–5.3 release prep; 3.2 SSO paperwork kickoff |
| **2** | 2 + 3 + 4 | Sandbox token; profile + dashboard APIs; start 4.2–4.3 | 3.2 ∥ 3.3 backend; 5.6–5.7 Play listing draft |
| **3** | 3 + 4 | SSO WebView + deep link; 4.4 eligible, 4.5 availed | 3.3 backend ∥ 3.5 mobile; QA 4.12 on finished screens |
| **4** | 4 | 4.6 consents, 4.7 OTP flow | 4.8 documents ∥ 4.9 reports (split devs) |
| **5** | 4 | 4.10 notifications; 4.0a error states | 4.11 i18n; 5.4 ProGuard |
| **6** | 3 + 4 | 3.11 UAT SSO (same APIs as web); 4.13 integration regression | 3.12 prod SSO cutover prep |
| **7** | 5 | 5.5 strip debug; 5.8 internal test track | 5.9 device matrix ∥ 5.10 smoke tests |
| **8** | 5 | 5.11 compliance review | 5.12 AAB prep |
| **9** | 5 | 3.12 prod SSO cutover; 5.10 prod smoke | — |
| **10** | 5 | 5.12–5.13 production rollout; 5.14 monitoring | — |

---

## Dependency gates (what cannot be parallelized)

| Gate | Blocks | Must wait for |
|------|--------|---------------|
| **G1** — Release keystore | Production-signed APK/AAB | 1.7, 1.8 |
| **G2** — API client + token storage | All Phase 4 screens | 2.4, 2.6, 2.5a |
| **G3** — Sandbox / dev auth | Phase 4 development | 3.4 (`getSandBoxToken`) |
| **G4** — Production SSO | 4.1 prod login, 5.10 prod smoke, 5.13 rollout | 3.12 |
| **G5** — Feature-complete citizen app | Release candidate | 4.13 |
| **G6** — Production rollout | Live app | G4 + G5 + 5.11 |
| **G7** — CITIZEN ACL on nextquery | Eligible / consent / notification lists | 2.13 (Backend confirms CITIZEN role permissions) |

---

## Risk register

| Risk | Impact | Mitigation | Owner |
|------|--------|------------|-------|
| Raj SSO redirect URI delay | Mitigated | **3.2 Done** — backend `mobile-browser-landing` + registration package; Raj SSO POST config is optional follow-up | Mobile Dev |
| Backend cookie-only SSO on `/landing` | Mitigated | **3.3 Done** (`/mobile-landing` JSON); fallback **3.7a** (Set-Cookie from same `/landing`) | Backend Dev |
| ACL 403 on nextquery (CITIZEN role) | All lists fail | Task 2.13 — verify `EligibleServices`, `CitizenServiceConsent`, `NotificationRequest` permissions in ACL | Backend Dev |
| Wrong OTP API used | Consent flow breaks | Use `CitizenConsentController` endpoints only (task 4.7), not raw `/open/otp-transaction` | Mobile Dev |
| API mismatch vs web | Rework in Phase 4 | Mirror `smart_frontend` components listed in backend review section | Mobile Dev |
| `/sso/family-list` hardcoded member ID | Broken family feature if integrated early | Exclude from v1; wait for backend fix | Mobile Dev |
| Debug signing in release | Play Store rejection | Complete 1.7–1.8 in Week 1 | Release Owner |
| Emulator cannot reach localhost | Dev blocked | Document `10.0.2.2:8080` vs LAN IP | Mobile Dev |
| Gov security audit | +1–2 weeks on Phase 5 | Start 5.6, 5.11 paperwork in Week 2 | Release Owner |

---

## Deliverables checklist

### Phase 1
- [x] Debug & release APK/AAB build scripts documented — [`README.md`](../README.md), [`tool/BUILD.md`](BUILD.md)
- [x] Production keystore configured  

### Phase 2
- [x] `SmartApiClient` + `NextQueryClient` + `AuthService`  
- [x] UAT profile & dashboard API working  
- [ ] CITIZEN ACL verified on nextquery models — **2.13 not complete**

### Phase 3
- [x] Mobile SSO API parity with web — same `/api/sso/*`, dashboard, headers (confirmed 27 Jun 2026)
- [ ] Production Raj SSO login on Android — **mobile flow implemented; 3.11 / 3.12 device sign-off pending**
- [x] Secure JWT lifecycle (login / logout via `/sso/signout` / expiry) — **verify on device in 3.11**

### Phase 4
- [x] All citizen screens on live APIs (nextquery + CitizenConsent) — **mock disabled in release**
- [ ] Consent OTP E2E via `/CitizenConsent/*` on UAT with real SMS
- [ ] QA regression sign-off — **automated tests green; manual checklist open**

### Phase 5
- [ ] Signed production AAB  
- [ ] Play Store / MDM rollout  
- [ ] Post-release monitoring  

---

## Reference — key backend endpoints (verified latest)

### Authentication & profile

| Feature | Method | Path | Auth |
|---------|--------|------|------|
| SSO landing (prod) | POST | `/smart/api/sso/landing?userdetails=` | permitAll (returns cookie + redirect) |
| SSO mobile landing (prod) | POST | `/smart/api/sso/mobile-landing?userdetails=` | permitAll → `{ "token", "currentSrole", "redirectPath" }` |
| SSO sandbox landing (UAT) | POST | `/smart/api/sso/sandboxlanding?userdetails=&ssoId=` | permitAll |
| Sandbox JWT (UAT dev) | POST | `/smart/api/sso/getSandBoxToken?userdetails=` | permitAll → `{ "token" }` |
| SSO sign out | POST | `/smart/api/sso/signout` | Body: `{ "userdetails" }` |
| Profile | POST | `/smart/api/sso/getProfile` | Body: `{ "ssoId", "userId" }` |
| Family list | POST | `/smart/api/sso/family-list` | **WIP — do not use in v1** |

### Dashboard

| Feature | Method | Path | Auth |
|---------|--------|------|------|
| Citizen dashboard counts | POST | `/smart/api/dashboard/citizenDashboardCount` | Form: `ssoId`, `userId` — **JWT required** |

### Nextquery (lists, create, update) — JWT + ACL required

| Feature | Method | Path |
|---------|--------|------|
| List with count | POST | `/smart/api/nextquery/{Model}/list-count` |
| List | POST | `/smart/api/nextquery/{Model}/list` |
| Create | POST | `/smart/api/nextquery/{Model}/create` |
| Update | POST | `/smart/api/nextquery/{Model}/update/{idField}/{idValue}` |

**Citizen models (from `NextQueryConfig`):** `EligibleServices`, `CitizenServiceConsent`, `CitizenEligibleServices`, `NotificationRequest`, `CitizenMemberProfile`

**Availed services filter:** `{ "executeActionName": "CitizenAvailedServiceList" }`

### Citizen consent OTP — JWT required

| Feature | Method | Path |
|---------|--------|------|
| Send consent OTP | GET | `/smart/api/CitizenConsent/sendConsentOTP?consentId={eligibleServiceId}` |
| Validate consent OTP | GET | `/smart/api/CitizenConsent/validateConsentOTP?tid={transactionId}&otp={code}` |

### Documents & certificates

| Feature | Method | Path |
|---------|--------|------|
| eMitra token | POST | `/smart/api/emitra/token` |
| Domicile PDF | GET | `/smart/api/open/domicile-certificate/pdf?eligibleServiceRecordId=&userId=` |
| S3 file preview | GET | `/smart/api/service/s3/preview/{folderName}/{fileName}` |
| eVault upload | POST | `/smart/api/open/evault/upload-document` |

### Low-level OTP (internal — used by CitizenConsent, not called directly from mobile)

| Feature | Method | Path |
|---------|--------|------|
| Send OTP | POST | `/smart/api/open/otp-transaction/send-otp` |
| Validate OTP | POST | `/smart/api/open/otp-transaction/validate-otp` |
| Resend OTP | POST | `/smart/api/open/otp-transaction/resend-otp` |

### Required mobile request headers

```http
Authorization: Bearer <jwt>
Content-Type: application/json
X-Current-Role: citizen
```

**Web reference:** `smart_frontend/utils/api-fetcher.ts`, `smart_frontend/store/authStore.ts`, `smart_frontend/components/SchemeVerificationModal.tsx`

---

## Document maintenance

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-06-27 | — | Initial production plan (Phases 1–5) |
| 1.1 | 2026-06-27 | — | Re-reviewed `smart_backend_mono` latest: CitizenConsent OTP flow, nextquery ACL, availed filter, notifications model, SSO signout, emitra/docs endpoints, family-list WIP, expanded endpoint reference |
| 1.2 | 2026-06-27 | — | Added **Status** column to all phase activity tables; status legend; removed inline ✓ markers from Parallel column |
| 1.3 | 2026-06-27 | — | Corrected **2.13** status to **In progress** (mobile ACL checks exist; Backend UAT verification not signed off) |
| 1.4 | 2026-06-27 | — | Phase progress snapshot table; aligned GATE/deliverables; **2.13** remains **In progress**; fixed **3.12**, **4.1**, **4.13** statuses |
| 1.5 | 2026-06-27 | — | Refreshed snapshot: **116** tests green; **3.12** / **4.13** automated tooling; QA artifact table; gate checklists aligned |
| 1.6 | 2026-06-27 | — | Re-ran `flutter test`: **115** passed, **4** skipped, **1** failed (widget smoke — icon asset); **2.13** remains **In progress** |
| 1.11 | 2026-06-27 | — | **3.2 Done** — `mobile-browser-landing`, registration package, `SSO_3.2_COMPLETION.md` |
| 1.8 | 2026-06-27 | — | **4.0a** / **4.0b** / **4.1** complete: `data_screen_states.dart`, `login_screen.dart`, i18n polish; **116** tests green |
| 1.9 | 2026-06-27 | — | **3.11** automated pre-login PASS (7/7 live UAT); `test/integration/sso_uat_test.dart`; manual device TC-01–TC-08 still pending for GATE |
| 1.10 | 2026-06-27 | — | Snapshot refresh: **116** passed, **6** skipped, **0** failed; **2.13** remains **In progress** |

Update this document when scope, team size, or SSO timeline changes.
