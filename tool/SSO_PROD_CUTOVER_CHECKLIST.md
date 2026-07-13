# SMART Rajasthan — Production SSO Cutover Checklist (Activity 3.12)

**Gate:** Production release requires this checklist **and** 3.11 UAT pass **and** 3.2 redirect URI registration confirmed.

---

## Prerequisites (block cutover if incomplete)

| ID | Item | Owner | Done |
|----|------|-------|------|
| P1 | **3.2** — Raj SSO redirect URIs registered (`smartrajasthan://sso-callback`, prod App Link) | SSO Coordinator | ☐ |
| P2 | **3.3** — `POST /smart/api/sso/mobile-landing` returns JSON `{ token }` on prod | Backend | ☐ |
| P3 | **3.11** — UAT SSO pass on physical devices (`tool/SSO_UAT_RESULTS_TEMPLATE.md`) | QA | ☐ |
| P4 | Production `assetlinks.json` on `https://smart.rajasthan.gov.in/.well-known/assetlinks.json` | Infra | ☐ |
| P5 | Release keystore + signed AAB/APK (Phase 1.7–1.8) | Release Owner | ☐ |

---

## Mobile build (production)

```powershell
cd MobileApp/smart_rajasthan-main/smart_rajasthan-main
flutter build apk --release --dart-define=USE_MOCK=false --dart-define=SMART_ENV=prod
# or appbundle for Play Store
flutter build appbundle --release --dart-define=USE_MOCK=false --dart-define=SMART_ENV=prod
```

**Verify on device:**

- [ ] Login screen shows **Raj SSO only** (no mock fields, no sandbox JWT button)
- [ ] Raj SSO opens `https://sso.rajasthan.gov.in/signin?ru=SMART`
- [ ] Callback returns to app via `smartrajasthan://sso-callback` or prod App Link
- [ ] JWT stored in secure storage; dashboard loads live data

---

## Automated regression (CI / before cutover)

### Pre-login probes (no Raj SSO login required)

```powershell
flutter test test/integration/sso_prod_cutover_test.dart `
  --dart-define=RUN_PROD_CUTOVER_TEST=true `
  --dart-define=USE_MOCK=false `
  --dart-define=SMART_ENV=prod
```

Probes: prod env config, `/landing` route, `mobile-landing`, `assetlinks.json`, redirect URIs, release gating.

---

## In-app automated checks

On a **release APK** pointed at **prod**:

1. Sign in via Raj SSO (PC-01)
2. Open **SSO Prod Cutover (3.12)** (debug menu on login, or drawer when signed in on debug build with prod env)
3. Run **Pre-login** then **Post-login** checks
4. **Copy results** → paste into `tool/SSO_PROD_CUTOVER_RESULTS_2026-06-27.md` (then `SSO_PROD_SIGNOFF_TEMPLATE.md` for GATE)

---

## Manual production test cases

| ID | Test | Pass |
|----|------|------|
| PC-01 | Release APK + prod env — full Raj SSO login | ☐ |
| PC-02 | Prod HTTPS App Link callback (if enabled) | ☐ |
| PC-03 | Token from `mobile-landing` JSON (preferred over Set-Cookie) | ☐ |
| PC-04 | Cold start session restore | ☐ |
| PC-05 | Logout clears JWT + calls `/api/sso/signout` | ☐ |
| PC-06 | Session expiry (401 or JWT exp) → login + message | ☐ |
| PC-07 | SSO team written confirmation for 3.2 | ☐ |
| PC-08 | `assetlinks.json` verified on prod host | ☐ |

---

## Rollback plan

| Trigger | Action |
|---------|--------|
| Prod SSO login failure > X% | Pause Play Store rollout; keep UAT build for internal users |
| Backend landing outage | Roll back backend deploy; mobile unchanged (retry when API restored) |
| Wrong redirect URI | SSO team re-register; ship hotfix only if manifest change required |

---

## Sign-off

Complete `tool/SSO_PROD_SIGNOFF_TEMPLATE.md` and attach release APK hash / version code.

**Phase 3 GATE complete when all roles sign 3.12.**
