# CITIZEN ACL verification (activity 2.13)

Mobile app activity **2.13** confirms that a citizen JWT with header `X-Current-Role: CITIZEN` can **VIEW** the nextquery models used by Phase 4 screens. Failures return HTTP **403** from the backend ACL layer.

## Models checked

| Model | Action | Backend hook / filter | Mobile use |
| :--- | :--- | :--- | :--- |
| `EligibleServices` | `VIEW` | `executeActionName=CitizenEligibleServiceList` | Eligible schemes (4.4) |
| `EligibleServices` | `VIEW` | `executeActionName=CitizenAvailedServiceList` | Availed schemes (4.5) |
| `CitizenServiceConsent` | `VIEW` | `consenterSmCitizenId=<smUserId from JWT>` | Consent list (4.6) |
| `NotificationRequest` | `VIEW` | `executeActionName=CitizenNotification` | Notifications (4.10) |

Canonical list in code: `CitizenAclRequirements.models` (`lib/config/citizen_nextquery.dart`).

## Backend remediation

Grant **VIEW** on each resource for role **CITIZEN** in `ACL_ROLE_PERMISSION` (see `smart_backend_mono/AUTH_ACL_DOC.md`).

Example rows (adjust IDs / audit columns per your DB conventions):

```sql
-- EligibleServices (eligible + availed hooks share the same model permission)
INSERT INTO ACL_ROLE_PERMISSION (ROLE_NAME, RESOURCE_NAME, ACTION_NAME)
VALUES ('CITIZEN', 'EligibleServices', 'VIEW');

INSERT INTO ACL_ROLE_PERMISSION (ROLE_NAME, RESOURCE_NAME, ACTION_NAME)
VALUES ('CITIZEN', 'CitizenServiceConsent', 'VIEW');

INSERT INTO ACL_ROLE_PERMISSION (ROLE_NAME, RESOURCE_NAME, ACTION_NAME)
VALUES ('CITIZEN', 'NotificationRequest', 'VIEW');
```

After DB changes, flush the Caffeine ACL cache (restart app server or use cache debug endpoint documented in `AUTH_ACL_DOC.md`).

## How to run (mobile)

### Unit tests (mock HTTP, no backend)

```powershell
cd MobileApp/smart_rajasthan-main/smart_rajasthan-main
flutter test test/services/citizen_acl_verification_test.dart
```

### In-app (UAT device / emulator)

1. `flutter run --dart-define=USE_MOCK=false`
2. Sign in (sandbox JWT or SSO UAT flow).
3. Open **Dev connectivity** screen → **Run ACL only (2.13)**.
4. Use **Copy** to paste results into this file under **Sign-off results**.

### Integration test (live UAT, optional)

Requires a stored JWT from a prior sandbox login on the test host:

```powershell
flutter test test/integration/citizen_acl_verification_test.dart `
  --dart-define=RUN_ACL_TEST=true `
  --dart-define=USE_MOCK=false
```

ACL is also included in the full UAT gate (`test/integration/uat_connectivity_test.dart` with `RUN_UAT_TEST=true`).

## Sign-off results

Paste copied markdown from the dev screen or integration test output here.

<!-- Example:
## ACL verification (2026-06-27T...)
- Environment: UAT
- Result: PASS (5/5)
-->

## Expected headers

Every nextquery call from the app sends:

- `Authorization: Bearer <jwt>`
- `X-Current-Role: CITIZEN`

If role header or JWT is wrong, ACL may pass authentication but still deny specific models.
