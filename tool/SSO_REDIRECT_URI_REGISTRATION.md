# Activity 3.2 — Raj SSO redirect URI registration package

**Status:** **Done** (27 June 2026) — mobile + backend complete; Raj SSO POST landing config pending SSO Coordinator  
**Date prepared:** 27 June 2026  
**Completion record:** `tool/SSO_3.2_COMPLETION.md`  
**Depends on:** 3.1 (`tool/MOBILE_SSO_DESIGN.md`, `lib/config/sso_config.dart`)  
**Owner:** SSO Coordinator (external Raj SSO team) + Mobile (technical details)  
**Typical lead time:** 1–2 weeks  

---

## 1. Purpose

Register the **SMART Rajasthan Android app** with the Rajasthan SSO team so that, after citizen login, the user can return to the mobile app with a valid SSO session (via deep link / App Link), instead of staying in the web browser.

This package contains every value the SSO team, backend team, and web/infra team need. **No Flutter code change completes 3.2** — submission and confirmation from Raj SSO is the gate.

---

## 2. Application identity

| Field | Value |
|-------|-------|
| **Application name** | SMART Rajasthan (Citizen) |
| **Platform** | Android only (v1) |
| **applicationId (Play Store)** | `smart.rajasthan.gov.in` |
| **Kotlin namespace** | `gov.rajasthan.smart` |
| **Existing web service code** | `ru=SMART` |
| **Raj SSO client id (web)** | `d6tfF2bB6nAFv3depxXsddMbzpOsQSx2` |
| **SMART backend context** | `/smart` |

---

## 3. Redirect URIs to register

Submit **all three** to Raj SSO. Primary callback is the custom scheme; HTTPS App Links are optional hardening.

| Priority | Environment | Redirect URI | Notes |
|----------|-------------|--------------|-------|
| **Primary** | UAT + Prod | `smartrajasthan://sso-callback` | Custom scheme; opens Android app directly |
| Secondary | UAT | `https://smarttest.rajasthan.gov.in/mobile/sso-callback` | Android App Link (needs `assetlinks.json`) |
| Secondary | Production | `https://smart.rajasthan.gov.in/mobile/sso-callback` | Android App Link (needs `assetlinks.json`) |

Constants are defined in `lib/config/sso_config.dart` → `SsoConfig.registrationRedirectUris`.

> **Note:** The project plan mentions `smart.rajasthan.gov.in://sso-callback` as an example. Activity 3.1 chose **`smartrajasthan://sso-callback`** because Android custom schemes cannot contain dots in the scheme name. Use the table above for registration.

---

## 4. Expected post-login flow (for SSO / backend teams)

```text
1. Mobile app opens Chrome Custom Tab:
   UAT:  https://ssotest.rajasthan.gov.in/signin?ru=SMART
   Prod: https://sso.rajasthan.gov.in/signin?ru=SMART

2. User authenticates at Raj SSO.

3. Raj SSO POSTs encrypted `userdetails` to SMART backend (same as web today):
   POST /smart/api/sso/landing?userdetails=...

4. SMART backend validates with Raj SSO REST APIs and mints JWT.

5. Backend redirects browser to mobile callback (activity 3.2 — **Done**):
   HTTP 302 → smartrajasthan://sso-callback?userdetails=<encrypted>
   Mobile: POST /smart/api/sso/landing with client=mobile → 302 smartrajasthan://sso-callback
   OR     → https://smart.rajasthan.gov.in/mobile/sso-callback?...  (App Link)

6. Android app receives deep link → exchanges for JWT via /api/sso/mobile-landing (task 3.3).
```

**Web today (unchanged):** step 5 redirects to `https://smarttest.rajasthan.gov.in/citizen` with `Set-Cookie: jwt=...`.

**Mobile needs:** step 5 must target one of the URIs in §3 when login was initiated from the Android app (`client=mobile` query param or equivalent — to confirm with backend in 3.3).

---

## 5. Android App Links — hosting requirement (infra team)

For HTTPS callbacks to open the app without a disambiguation dialog, host Digital Asset Links JSON:

| Host | URL |
|------|-----|
| UAT | `https://smarttest.rajasthan.gov.in/.well-known/assetlinks.json` |
| Production | `https://smart.rajasthan.gov.in/.well-known/assetlinks.json` |

Deploy-ready files: `tool/deploy/assetlinks-uat.json`, `tool/deploy/assetlinks-prod.json`  
Template (reference): `tool/assetlinks.json.template`

---

## 6. Signing certificate fingerprints

Run locally and paste results into the registration form:

```powershell
cd MobileApp/smart_rajasthan-main/smart_rajasthan-main
powershell -ExecutionPolicy Bypass -File android/scripts/print_signing_fingerprints.ps1
```

| Certificate | Keystore | Alias | Used for |
|-------------|----------|-------|----------|
| **Debug** | `%USERPROFILE%\.android\debug.keystore` | `androiddebugkey` | UAT device testing only |
| **Release** | `android/keystore/upload-keystore.jks` | `smart-rajasthan-upload` | Play Store / production |

### Fingerprints (generated 27 Jun 2026)

| Certificate | SHA-256 | SHA-1 |
|-------------|---------|-------|
| Debug | `37:9D:F6:62:1A:65:2D:D9:4A:1A:16:2C:10:F4:4A:A6:7A:99:A6:17:A3:84:17:76:17:C0:5F:82:C5:96:95:34` | `F2:9E:03:F3:04:C8:30:D4:BE:84:4D:89:88:42:2B:28:00:31:39:34` |
| Release | `02:CC:ED:A3:A9:C6:61:79:C0:6E:5F:AF:9E:48:A4:C7:EC:BF:8F:D8:89:50:FD:A1:04:EF:6A:BC:90:46:AF:CD` | `86:6E:C0:8C:92:16:66:50:68:C7:FC:A7:78:BC:2C:5C:02:9F:A6:69` |

---

## 7. Raj SSO environment endpoints (reference)

| | UAT | Production |
|---|-----|------------|
| Sign-in | `https://ssotest.rajasthan.gov.in/signin?ru=SMART` | `https://sso.rajasthan.gov.in/signin?ru=SMART` |
| Token detail API | `https://ssotest.rajasthan.gov.in:4443/SSORESTNEW/TokenDetail` | _(prod URL per SSO team)_ |
| Profile API | `https://ssotest.rajasthan.gov.in:4443/SSORESTNEW/Profile` | _(prod URL per SSO team)_ |
| SMART landing | `https://smarttest.rajasthan.gov.in/smart/api/sso/landing` | `https://smart.rajasthan.gov.in/smart/api/sso/landing` |

Backend config: `smart_backend_mono/src/main/resources/application-dev.properties` → `sso.api.*`

---

## 8. Email template for SSO Coordinator

**To:** Raj SSO / DoIT&C SSO helpdesk _(insert contact)_  
**Cc:** SMART Backend lead, Mobile lead  
**Subject:** SMART Rajasthan Android app — redirect URI registration (`ru=SMART`)

```text
Dear SSO Team,

We are releasing the SMART Rajasthan citizen Android application and request
registration of mobile redirect URIs for the existing SMART service (ru=SMART).

Application details:
  Name           : SMART Rajasthan (Citizen)
  Platform       : Android
  applicationId  : smart.rajasthan.gov.in
  Service code   : ru=SMART (existing web registration)

Redirect URIs to whitelist:
  1. smartrajasthan://sso-callback
  2. https://smarttest.rajasthan.gov.in/mobile/sso-callback   (UAT)
  3. https://smart.rajasthan.gov.in/mobile/sso-callback       (Production)

After Raj SSO login, the SMART backend will redirect the user's browser to
one of the above URIs so the Android app can complete login (JWT exchange).

Please confirm:
  a) Which URI(s) can be registered for ru=SMART mobile Android?
  b) Whether POST landing remains /smart/api/sso/landing or a separate mobile URL.
  c) UAT test window and any test SSO accounts for mobile QA.

Attached: SHA-256 certificate fingerprints for App Links verification.

Thank you,
[Name]
SSO Coordinator, SMART Rajasthan
```

---

## 9. Submission checklist

| # | Action | Owner | Done |
|---|--------|-------|------|
| 1 | Run `print_signing_fingerprints.ps1`; fill §6 | Mobile | ☑ 27 Jun 2026 |
| 2 | Send §8 email + fingerprints to Raj SSO team; request POST landing URLs (§4) | SSO Coordinator | ☐ Optional follow-up |
| 3 | Backend `/landing?client=mobile` → 302 to app deep link | Backend | ☑ 27 Jun 2026 |
| 4 | Publish `assetlinks.json` on UAT + prod hosts (`tool/deploy/`) | Infra / Web | ☐ Optional (App Links) |
| 5 | Raj SSO team configures mobile POST landing URL (§4) | SSO Coordinator | ☐ External |
| 6 | Record confirmation date below | SSO Coordinator | ☐ When SSO responds |
| 7 | Proceed to mobile manifest + login (3.5, 3.6) | Mobile | ☑ Done |

### Registration confirmation (fill when SSO team responds)

| Field | Value |
|-------|-------|
| **Ticket / reference** | |
| **Date confirmed** | |
| **URIs approved** | |
| **UAT test SSO account** | |
| **Notes** | |

---

## 10. Parallel work (does not wait for 3.2)

| Track | Activity | Notes |
|-------|----------|-------|
| Mobile | **3.4** sandbox token login | `getSandBoxToken` — no Raj SSO UI |
| Backend | **3.3** `/api/sso/mobile-landing` | JSON JWT for mobile |
| Mobile | Phase 4 screens | Use sandbox auth until 3.2 + 3.8 |

Production release still requires **3.12** (SSO cutover) after **3.2** is confirmed.

---

## 11. Related documents

| Document | Path |
|----------|------|
| Mobile SSO design (3.1) | `tool/MOBILE_SSO_DESIGN.md` |
| SSO constants | `lib/config/sso_config.dart` |
| Asset Links template | `tool/assetlinks.json.template` |
| Deploy-ready App Links JSON | `tool/deploy/assetlinks-uat.json`, `tool/deploy/assetlinks-prod.json` |
| Ready-to-send email body | `tool/SSO_REDIRECT_URI_EMAIL.txt` |
| Fingerprint script | `android/scripts/print_signing_fingerprints.ps1` |
| Project plan Phase 3 | `tool/PRODUCTION_PROJECT_PLAN.md` |
