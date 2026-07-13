# SMART Rajasthan — Production SSO Sign-off (Activity 3.12)

**Cutover date:** YYYY-MM-DD  
**App version:** `1.0.0+1` (versionCode ______)  
**Release artifact:** `app-release.apk` / `app-release.aab` SHA-256:  
**Backend:** `https://smart.rajasthan.gov.in/smart`  
**Raj SSO:** `https://sso.rajasthan.gov.in/signin?ru=SMART`  

---

## Prerequisites verified

| Item | Status | Evidence |
|------|--------|----------|
| 3.2 Redirect URIs registered | ☐ Yes ☐ No | Email / ticket # |
| 3.3 mobile-landing on prod | ☐ Yes ☐ No | HTTP probe / backend tag |
| 3.11 UAT pass | ☐ Yes ☐ No | `SSO_UAT_RESULTS_TEMPLATE.md` |
| assetlinks.json live | ☐ Yes ☐ No | URL check |

---

## Device matrix (production)

| Device | Model | Android | APK type | Network | Tester | PC-01 |
|--------|-------|---------|----------|---------|--------|-------|
| | | | release | | | ☐ |

---

## Automated cutover checks (in-app 3.12 runner)

### Pre-login

```
(paste Copy results — pre-login section)
```

### Post-login (after PC-01)

```
(paste Copy results — post-login section)
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

## Defects at cutover

| ID | Severity | Summary | Resolution |
|----|----------|---------|------------|
| | | | |

---

## Overall result

- [ ] **3.12 PASS** — Phase 3 GATE complete; approved for Phase 5 production rollout  
- [ ] **3.12 FAIL** — blockers:  

| Role | Name | Signature / date |
|------|------|------------------|
| Mobile Dev | | |
| QA Lead | | |
| SSO Coordinator | | |
| Release Owner | | |
