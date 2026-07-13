# Activity 3.2 & 3.11 — Action list (SSO Coordinator + QA)

**Date:** 27 June 2026  
**3.2 status:** **Done** (see `tool/SSO_3.2_COMPLETION.md`)  
**Goal:** Complete UAT SSO sign-off on physical devices (3.11).  
**Blocks production cutover (3.12) until 3.11 is done.**

---

## SSO Coordinator (optional follow-up)

3.2 mobile + backend deliverables are **Done**. Optional external step:

1. **Send mobile POST landing email**  
   - Copy body from `tool/SSO_REDIRECT_URI_EMAIL.txt`  
   - Attach `tool/SSO_REDIRECT_URI_REGISTRATION.md` or `tool/SSO_3.2_COMPLETION.md`  
   - **To:** Raj SSO / DoIT&C helpdesk _(insert contact)_  

2. **Request Raj SSO configure POST landing:**
   - UAT: `https://smarttest.rajasthan.gov.in/smart/api/sso/landing` (mobile: sign-in with `client=mobile`)
   - Prod: `https://smart.rajasthan.gov.in/smart/api/sso/landing`

3. **Record confirmation** in `tool/SSO_REDIRECT_URI_REGISTRATION.md` §9 when SSO responds.

### Coordinate with other teams

| Action | Owner | When |
|--------|-------|------|
| Backend redirects browser to `smartrajasthan://sso-callback?...` after mobile SSO login (not web `/citizen` only) | Backend | After SSO confirms URIs |
| Publish `tool/deploy/assetlinks-uat.json` → `https://smarttest.rajasthan.gov.in/.well-known/assetlinks.json` | Infra / Web | Parallel with UAT testing |
| Publish `tool/deploy/assetlinks-prod.json` → `https://smart.rajasthan.gov.in/.well-known/assetlinks.json` | Infra / Web | Before prod cutover (3.12) |

### Sign-off (after QA completes 3.11)

- [ ] Confirm 3.2 registration is live on UAT (and prod before 3.12)  
- [ ] Sign `tool/SSO_UAT_RESULTS_<date>.md` SSO Coordinator row  

---

## QA

### Can start now (no 3.2 dependency)

1. **Build UAT release APK** (Mobile can assist):
   ```bash
   flutter build apk --release --dart-define=USE_MOCK=false --dart-define=SMART_ENV=uat
   ```
2. **Install on ≥2 physical devices** (Android 8–14; one low-RAM if possible). Fill device matrix in `tool/SSO_UAT_RESULTS_2026-06-27.md`.
3. **Open app → Login or Drawer → SSO UAT (3.11)** → run **1. Pre-login config checks** → paste results into results file.
4. **TC-08 — Release APK gating:** confirm mock login and sandbox JWT button are **absent**; only **Login with Raj SSO** is shown.
5. **TC-06 — Invalid callback** (no SSO needed):
   ```bash
   adb shell am start -a android.intent.action.VIEW -d "smartrajasthan://sso-callback?error=denied"
   ```
   Expect: friendly error, stay on login screen.

### After backend deploy + Raj SSO POST landing configured

6. **TC-01 — Raj SSO happy path (P0)**  
   Tap **Login with Raj SSO** → sign in on UAT → app returns via deep link → dashboard loads with real data.

7. **Run in-app automated checks** (SSO UAT screen):  
   - **2. Post-login verification**  
   - **3. Logout check**

8. **TC-02 — Cold start:** force-stop app → relaunch → dashboard without re-login.

9. **TC-07 — Session expiry:** wait for JWT expiry or trigger 401 → login screen with message.

10. **Optional:** TC-03 (background callback), TC-05 (cancel SSO), TC-04 (WebView fallback).

### Close-out

11. **Mark pass/fail** for each TC in `tool/SSO_UAT_RESULTS_2026-06-27.md`.  
12. **3.11 PASS criteria** (all required):
    - TC-01, TC-02, TC-07, TC-08 pass on ≥2 physical devices  
    - Automated post-login + logout checks pass  
    - No open P0/P1 defects  
13. **Sign-off:** QA + Mobile Dev rows in results file.

---

## Sequence

```text
3.2 Done (mobile + backend)
        ↓
Deploy backend + Raj SSO POST landing (optional external)
        ↓
QA runs TC-01–TC-08 on devices
        ↓
3.11 PASS → 3.12 prod cutover
```

---

## Reference files

| File | Purpose |
|------|---------|
| `tool/SSO_REDIRECT_URI_EMAIL.txt` | Ready-to-send registration email |
| `tool/SSO_REDIRECT_URI_REGISTRATION.md` | Full 3.2 package + confirmation table |
| `tool/SSO_UAT_TEST_PLAN.md` | Detailed test cases |
| `tool/SSO_UAT_RESULTS_2026-06-27.md` | Record results and sign-off |
| `tool/deploy/assetlinks-uat.json` | Infra deploy for UAT App Links |
