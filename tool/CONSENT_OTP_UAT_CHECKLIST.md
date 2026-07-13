# Consent OTP — UAT Verification Checklist

**Environment:** UAT (`https://smarttest.rajasthan.gov.in/smart`)  
**Mobile build:** `flutter build apk --release --dart-define=SMART_ENV=uat`  
**APIs:** `CitizenConsentController` — same as web `SchemeVerificationModal`

---

## Prerequisites

| # | Check | How | Pass |
|---|-------|-----|------|
| P1 | Test SSO account | Raj SSO UAT (`ssotest.rajasthan.gov.in`) | User can log in to mobile app |
| P2 | Jan Aadhaar in SSO profile | Raj SSO profile → Jan Aadhaar + Member ID | Both populated (required at **verify** step) |
| P3 | Eligible service row | Citizen → Consent → Provide Consent list | At least one CONSENT row visible |
| P4 | Mobile on eligible record | Backend `EligibleServices.mobile` for that row | Matches user's registered phone |

---

## API checks (curl / Postman)

Use JWT from mobile login (`Authorization: Bearer …`, `X-Current-Role: CITIZEN`).

### 1. Send OTP

```http
GET /smart/api/CitizenConsent/sendConsentOTP?consentId={eligibleServiceId}
Authorization: Bearer {jwt}
X-Current-Role: CITIZEN
```

**Expected (200):**

```json
{
  "data": {
    "transactionId": "...",
    "otpPrefix": "XXXX",
    "mobile": "*****1234",
    "status": "SUCCESS"
  }
}
```

**Failure examples (400):** missing mobile on eligible row, invalid `consentId`.

### 2. SMS delivery

- SMS template: `PREFIX - CODE` (6-digit code), valid ~10 minutes.
- UAT gateway: eSanchar (`esanchar.service.url` in backend `application-dev.properties`).
- If send returns 200 but no SMS: check backend logs for `OTP SMS send failed` on `OtpTransaction` record.

### 3. Validate OTP

```http
GET /smart/api/CitizenConsent/validateConsentOTP?tid={transactionId}&otp={6digits}&otpPrefix={prefix}
Authorization: Bearer {jwt}
X-Current-Role: CITIZEN
```

**Expected (200):**

```json
{
  "status": true,
  "isvalidate": true,
  "message": "OTP has been successfully validated"
}
```

**Failure (400):** wrong OTP, expired OTP, incomplete SSO profile (*"Please update your Jan Aadhaar and Member ID..."*).

---

## Mobile app E2E (device)

| # | Step | Expected |
|---|------|----------|
| M1 | Open Consent → Avail Service | Step 1: Send OTP |
| M2 | Incomplete SSO profile (no jfId/smUserId in JWT) | Blocked before send with Jan Aadhaar message |
| M3 | Send OTP | Step 2; shows masked mobile + OTP prefix hint |
| M4 | Enter wrong OTP → Verify | Snackbar with backend message (not `DioException` stack trace) |
| M5 | Resend OTP → enter correct code | Step 3: Submit Consent |
| M6 | Submit Consent | Success; eligible list refreshes |

---

## Backend follow-ups (if SMS still missing)

1. Re-enable `validateSsoProfile()` on **send** in `CitizenConsentController` (fail early).
2. Return `FAILED` when eSanchar SMS fails instead of HTTP 200 SUCCESS.
3. Confirm UAT eSanchar credentials and template id `1107178178631852874` in deployed UAT config.

---

## Sign-off

| Role | Name | Date | Result |
|------|------|------|--------|
| Mobile QA | | | |
| Backend / UAT | | | |
