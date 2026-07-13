# SMART Rajasthan — Production SSO Cutover Results (Activity 3.12)

**Cutover run date:** 2026-06-27  
**Environment:** Production  
**Build:** release APK / debug prod — version `1.0.0+1`  
**Backend:** `https://smart.rajasthan.gov.in/smart`  
**Raj SSO:** `https://sso.rajasthan.gov.in/signin?ru=SMART`  
**Tester(s):** _TBD_  

---

## Session notes

- **Harness:** Login or drawer → **SSO Prod Cutover (3.12)** (visible when `USE_MOCK=false` + `SMART_ENV=prod`).
- **Start here:** Run **1. Pre-login cutover checks** (infra + config; no Raj SSO login required).
- **After PC-01:** Run **2. Post-login prod verification** and **3. Logout check (PC-05)**.
- **CI probe:**
  ```powershell
  flutter test test/integration/sso_prod_cutover_test.dart `
    --dart-define=RUN_PROD_CUTOVER_TEST=true `
    --dart-define=USE_MOCK=false `
    --dart-define=SMART_ENV=prod
  ```
- **Prerequisites:** 3.2 redirect URIs · 3.11 UAT pass · release keystore (Phase 1.7)

---

## Device matrix (production)

| Device | Model | Android | Build type | Network | Tester | PC-01 |
|--------|-------|---------|------------|---------|--------|-------|
| | | | release | | | ☐ |

---

## Automated checks (from in-app 3.12 screen)

Paste output from **Copy results** after each run.

### Pre-login

```
(pending — run on prod build)
```

### Post-login (after PC-01)

```
(pending)
```

### Logout (PC-05)

```
(pending)
```

---

## Manual production tests

| ID | Pass | Notes |
|----|------|-------|
| PC-01 Raj SSO on release APK | ☐ | |
| PC-02 Prod App Link / deep link | ☐ | |
| PC-03 mobile-landing JSON token | ☐ | |
| PC-04 Cold start restore | ☐ | |
| PC-05 Logout + signout API | ☐ | |
| PC-06 Session expiry | ☐ | |
| PC-07 SSO team 3.2 confirmation | ☐ | |
| PC-08 assetlinks.json | ☐ | |

---

## Blockers

| Item | Owner | Status |
|------|-------|--------|
| 3.2 redirect URI registration | SSO Coordinator | Pending |
| 3.11 UAT device sign-off | QA | Pending |
| assetlinks.json on prod | Infra | Verify in pre-login probe |

---

## Overall

- [ ] **3.12 automated PASS**
- [ ] **3.12 manual PC-01–PC-08 PASS**
- [ ] **Phase 3 GATE complete** → copy to `SSO_PROD_SIGNOFF_TEMPLATE.md`
