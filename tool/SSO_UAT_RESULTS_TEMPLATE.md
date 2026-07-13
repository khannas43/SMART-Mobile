# SMART Rajasthan — SSO UAT Results (Activity 3.11)

**Test run date:** YYYY-MM-DD  
**Environment:** UAT / Production  
**Build:** `app-release.apk` or debug — version `1.0.0+1`  
**Backend:** `https://smarttest.rajasthan.gov.in/smart` (or prod)  
**Tester(s):**  
**Raj SSO redirect registered (3.2):** Yes / No / Pending  

---

## Device matrix

| Device | Model | Android | Build type | Network | Tester |
|--------|-------|---------|------------|---------|--------|
| | | | debug / release | | |

---

## Automated checks (from in-app SSO UAT screen)

Paste output from **Copy results** after each run.

### Pre-login config

```
(paste here)
```

### Post-login verification (after TC-01)

```
(paste here)
```

### Logout check (3.9)

```
(paste here)
```

---

## Manual test cases

| ID | Description | Device | Pass | Notes / defects |
|----|-------------|--------|------|-----------------|
| TC-01 | Raj SSO happy path | | ☐ | |
| TC-02 | Cold start restore | | ☐ | |
| TC-03 | Background callback | | ☐ | |
| TC-04 | WebView fallback | | ☐ | N/A if not tested |
| TC-05 | Cancel SSO | | ☐ | |
| TC-06 | Invalid callback | | ☐ | |
| TC-07 | Session expiry | | ☐ | |
| TC-08 | Release APK gating | | ☐ | |
| TC-09 | LAN dev backend | | ☐ | Optional |

---

## Defects

| ID | Severity | Summary | Status |
|----|----------|---------|--------|
| | P0/P1/P2 | | Open / Fixed |

---

## Overall result

- [ ] **3.11 PASS** — ready for 3.12 production cutover discussion  
- [ ] **3.11 FAIL** — blockers:  

| Role | Name | Sign-off date |
|------|------|---------------|
| Mobile Dev | | |
| QA | | |
| SSO Coordinator | | |
