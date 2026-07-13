# SMART Rajasthan — SSO UAT Test Plan (Activity 3.11)

**Document version:** 1.0  
**Date:** 27 June 2026  
**Owners:** Mobile Dev + QA  
**Depends on:** 3.8 (JWT in secure storage), backend UAT (same SSO APIs as web)  
**Related:** `tool/MOBILE_SSO_DESIGN.md`, `tool/SSO_REDIRECT_URI_REGISTRATION.md`

---

## 1. Objective

Verify **end-to-end Rajasthan SSO login on Android physical devices** (UAT first, then production), including JWT lifecycle, API access, logout, and session expiry — matching Phase 3 GATE in `PRODUCTION_PROJECT_PLAN.md`.

This plan covers **manual device tests** (TC-01–TC-09) plus **automated checks** runnable from the in-app **SSO UAT (3.11)** screen.

---

## 2. Preconditions

| # | Requirement | Owner | Status |
|---|-------------|-------|--------|
| P1 | Raj SSO operational on web (`signin?ru=SMART`) — mobile uses same backend | Backend | ☑ |
| P2 | `/api/sso/mobile-landing` or `/landing` + `/sandboxlanding` reachable | Backend | ☑ (automated probe) |
| P3 | UAT backend reachable: `https://smarttest.rajasthan.gov.in/smart` | Infra | ☑ |
| P4 | Test citizen SSO account for device TC-01 | QA | ☐ |
| P5 | App built with `--dart-define=USE_MOCK=false` | Mobile | ☐ on device |
| P6 | Release APK built for TC-08 | Mobile | ☐ |

**Interim:** Sandbox JWT (`getSandBoxToken`) validates post-login APIs but does **not** replace TC-01 (Raj SSO Custom Tab on device).

---

## 3. Device matrix (minimum)

| Device | Android | RAM | Network | Build | Tester |
|--------|---------|-----|---------|-------|--------|
| Phone A | 12–14 | ≥4 GB | Wi‑Fi / mobile data | Debug UAT | |
| Phone B | 8–11 | ≥2 GB | Wi‑Fi | Release UAT | |
| (Optional) Emulator | — | — | Host LAN | Debug dev | Not a substitute for physical SSO |

---

## 4. Build & run commands

```bash
# Debug on physical device (UAT)
flutter run --dart-define=USE_MOCK=false --dart-define=SMART_ENV=uat

# Local backend on physical device (replace LAN IP)
flutter run --dart-define=SMART_ENV=dev \
  --dart-define=SMART_API_HOST=http://192.168.1.10:8080 \
  --dart-define=USE_MOCK=false

# Release APK for TC-08
flutter build apk --release --dart-define=USE_MOCK=false --dart-define=SMART_ENV=uat
```

Open **Login → SSO UAT (3.11)** or **Drawer → SSO UAT (3.11)** on UAT live builds (debug and **release UAT APK** for TC-08).

---

## 5. Automated checks (in-app)

Run from **SSO UAT (3.11)** screen:

| Step | When | Validates |
|------|------|-----------|
| **1. Pre-login config** | Before SSO | Live API mode, release gating, Raj SSO URL, callback URI parsing, backend + mobile-landing reachability |
| **2. Post-login verification** | After TC-01 | JWT session, expiry, secure storage, profile, dashboard |
| **3. Logout check** | After TC-01 | Logout clears JWT (3.9) — **signs user out** |

Copy results from the screen into `tool/SSO_UAT_RESULTS_<date>.md` (use template below).

---

## 6. Manual test cases

### TC-01 — Raj SSO happy path (Custom Tab → deep link)

**Priority:** P0  
**Build:** Debug UAT, `USE_MOCK=false`

| Step | Action | Expected |
|------|--------|----------|
| 1 | Tap **Login with Raj SSO** | Chrome Custom Tab opens `ssotest.rajasthan.gov.in/signin?ru=SMART` |
| 2 | Enter valid citizen credentials | Raj SSO accepts login |
| 3 | Complete redirect | App receives `smartrajasthan://sso-callback?userdetails=…` (or HTTPS App Link) |
| 4 | Observe app | Dashboard loads; no error snackbar |
| 5 | Run **Post-login verification** on SSO UAT screen | All automated checks pass |

**Pass criteria:** User reaches home with real profile/dashboard data.

---

### TC-02 — Cold start session restore

**Priority:** P0  
**Depends on:** TC-01

| Step | Action | Expected |
|------|--------|----------|
| 1 | After TC-01, force-stop app | — |
| 2 | Relaunch app | Opens dashboard without login prompt |
| 3 | Navigate schemes / profile | Data loads with stored JWT |

---

### TC-03 — SSO callback while app backgrounded

**Priority:** P1

| Step | Action | Expected |
|------|--------|----------|
| 1 | Start Raj SSO login | Custom Tab open |
| 2 | Switch to app home screen (app in background) | — |
| 3 | Complete SSO in browser | App foregrounds and completes login |

---

### TC-04 — WebView fallback

**Priority:** P2  
**Note:** Force fallback by device without Custom Tab or temporary code path to WebView.

| Step | Action | Expected |
|------|--------|----------|
| 1 | Open SSO via WebView fallback | In-app browser loads Raj SSO |
| 2 | Complete login | Callback intercepted; home screen |

---

### TC-05 — Cancel SSO / user abort

**Priority:** P1

| Step | Action | Expected |
|------|--------|----------|
| 1 | Open Custom Tab | Raj SSO visible |
| 2 | Close tab without logging in | App on login screen; no crash; can retry |

---

### TC-06 — Invalid callback

**Priority:** P2  
**Method:** `adb shell am start -a android.intent.action.VIEW -d "smartrajasthan://sso-callback?error=denied"`

| Step | Action | Expected |
|------|--------|----------|
| 1 | Inject invalid/error callback | User-friendly error; stays on login |

---

### TC-07 — Session expiry (3.10)

**Priority:** P0

| Step | Action | Expected |
|------|--------|----------|
| A | Wait until JWT `exp` passes (or use short-lived test token) | App redirects to login with expiry message |
| B | Or trigger API 401 with expired token | Session cleared; login screen |

---

### TC-08 — Release APK gating (3.8)

**Priority:** P0  
**Build:** Release UAT APK

| Check | Expected |
|-------|----------|
| Mock username/password bypass | **Absent** |
| Sandbox JWT button | **Absent** |
| Only **Login with Raj SSO** | Present |
| TC-01 on release build | Pass |

---

### TC-09 — LAN / dev backend (optional)

**Priority:** P3  
**Build:** `--dart-define=SMART_ENV=dev --dart-define=SMART_API_HOST=http://<LAN-IP>:8080`

Verify SSO + API when testing against local `smart_backend_mono` from a physical device on the same network.

---

## 7. Logout verification (3.9)

Manual + automated step **3** on SSO UAT screen:

| Step | Action | Expected |
|------|--------|----------|
| 1 | From drawer, tap **Logout** | Login screen |
| 2 | Confirm JWT cleared | Post-login check fails until re-login |
| 3 | (Optional) Backend logs | `POST /smart/api/sso/signout` with `{ userdetails }` |

---

## 8. Pass / fail criteria (3.11 GATE)

**PASS** when all are true on **≥2 physical devices**:

- [ ] TC-01, TC-02, TC-07, TC-08 pass on UAT  
- [ ] Automated post-login + logout checks pass after TC-01  
- [ ] No P0/P1 defects open  
- [ ] Results recorded in `tool/SSO_UAT_RESULTS_<date>.md`  
- [ ] QA + Mobile sign-off below  

**FAIL** if Raj SSO cannot return to app on device, or JWT exchange fails after login.

Automated pre-login (no device): `flutter test test/integration/sso_uat_test.dart --name "3.11 pre-login" --dart-define=RUN_SSO_UAT_TEST=true --dart-define=USE_MOCK=false --dart-define=SMART_ENV=uat`

---

## 9. Sign-off

| Role | Name | Date | UAT PASS | Prod PASS |
|------|------|------|----------|-----------|
| Mobile Dev | | | ☐ | ☐ |
| QA | | | ☐ | ☐ |
| SSO Coordinator | | | ☐ | ☐ |

---

## 10. References

| Artifact | Path |
|----------|------|
| In-app runner | `lib/screens/sso_uat_screen.dart` |
| Automated service | `lib/services/sso_uat_test.dart` |
| SSO design checklist | `tool/MOBILE_SSO_DESIGN.md` §12 |
| Redirect registration | `tool/SSO_REDIRECT_URI_REGISTRATION.md` |
| Results template | `tool/SSO_UAT_RESULTS_TEMPLATE.md` |
