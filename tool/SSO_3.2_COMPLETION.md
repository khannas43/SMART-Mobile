# Activity 3.2 — Completion record

**Date:** 27 June 2026  
**Status:** **Done** (mobile + backend deliverables)

---

## Summary

Activity 3.2 registers the SMART Rajasthan Android app for Raj SSO mobile login return. All **in-repo deliverables** are complete. Raj SSO team must point the mobile browser POST landing to the new backend endpoint (see §3).

---

## Completed deliverables

| # | Item | Location |
|---|------|----------|
| 1 | Redirect URI constants | `lib/config/sso_config.dart` |
| 2 | Android deep link + App Link intent-filters | `android/app/src/main/AndroidManifest.xml` |
| 3 | Registration package + fingerprints | `tool/SSO_REDIRECT_URI_REGISTRATION.md` |
| 4 | Ready-to-send email | `tool/SSO_REDIRECT_URI_EMAIL.txt` |
| 5 | App Links JSON (UAT + prod) | `tool/deploy/assetlinks-uat.json`, `assetlinks-prod.json` |
| 6 | Backend mobile redirect on `/landing` | `POST /smart/api/sso/landing?client=mobile` |
| 7 | Backend config | `sso.api.mobileCallbackUri=smartrajasthan://sso-callback` |
| 8 | Mobile sign-in hint | `?ru=SMART&client=mobile` on Raj SSO URL |
| 9 | UAT pre-login probe | `SsoUatTest` step `landing-mobile` |

---

## Redirect URIs (registered set)

1. **Primary:** `smartrajasthan://sso-callback`
2. **UAT App Link:** `https://smarttest.rajasthan.gov.in/mobile/sso-callback`
3. **Prod App Link:** `https://smart.rajasthan.gov.in/mobile/sso-callback`

---

## Raj SSO team — configure POST landing (external)

After citizen login, Raj SSO auto-POSTs `userdetails` to SMART **`/landing`** (same as web). For Android, ensure sign-in uses `&client=mobile` so `/landing` returns the app deep link:

| Environment | Raj SSO POST landing URL |
|-------------|--------------------------|
| UAT | `https://smarttest.rajasthan.gov.in/smart/api/sso/landing` |
| Production | `https://smart.rajasthan.gov.in/smart/api/sso/landing` |

Mobile sign-in URL must include `client=mobile` (app already opens `…/signin?ru=SMART&client=mobile`). `/landing` detects mobile via `client=mobile`, Referer, or `X-SMART-Client: mobile` → `302 smartrajasthan://sso-callback?userdetails=…`.

Legacy alias `POST /mobile-browser-landing` delegates to `/landing?client=mobile` (deprecated).

---

## Optional follow-ups (not blocking 3.2 Done)

| Action | Owner |
|--------|-------|
| Send `tool/SSO_REDIRECT_URI_EMAIL.txt` to Raj SSO helpdesk | SSO Coordinator |
| Publish `assetlinks.json` on UAT/prod hosts | Infra |
| Record SSO ticket ID in registration doc §9 | SSO Coordinator |

---

## Unblocks

- **3.11** TC-01 Raj SSO happy path (with backend deploy + Raj SSO POST config)
- **3.12** production cutover (after 3.11 device sign-off)
