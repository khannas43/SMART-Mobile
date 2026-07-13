# SMART Rajasthan — Release Keystore Custody (Activity 1.7)

**Document version:** 1.0  
**Date:** 27 June 2026  
**Application ID:** `smart.rajasthan.gov.in`  
**Owner role:** Release Owner  

---

## Purpose

This document defines how the Android **release signing keystore** is created, stored, backed up, and used for Play Store / MDM distribution. Activity **1.8** wires this keystore into Gradle; activity **5.1** extends backup procedures for production rollout.

---

## Artifacts

| Artifact | Path | In git? |
|----------|------|---------|
| Keystore (PKCS12) | `android/keystore/upload-keystore.jks` | **No** |
| Signing credentials | `android/key.properties` | **No** |
| Template | `android/key.properties.example` | Yes |
| Generation script | `android/scripts/generate_release_keystore.ps1` | Yes |

**Key alias:** `smart-rajasthan-upload`  
**Algorithm:** RSA 2048  
**Validity:** 10 000 days (~27 years)  
**Distinguished name:** `CN=SMART Rajasthan, OU=Department of Information Technology and Communications, O=Government of Rajasthan, L=Jaipur, ST=Rajasthan, C=IN`

---

## One-time creation (Release Owner)

From PowerShell:

```powershell
Set-Location "d:\smart\Smart_Project_Code\MobileApp\smart_rajasthan-main\smart_rajasthan-main\android\scripts"
.\generate_release_keystore.ps1
```

Requirements:

- JDK `keytool` on `PATH` (bundled with Android Studio / JDK 17+)
- Run **once** per app signing identity; deleting and regenerating invalidates prior signed builds on Play Console

The script writes:

1. `android/keystore/upload-keystore.jks`
2. `android/key.properties` (store password, key password, alias, relative store path)

Passwords are generated cryptographically random (24-byte base64). They are **not** printed to the console.

---

## Custody chain

| Role | Responsibility |
|------|----------------|
| **Release Owner** | Primary custodian; holds keystore + passwords; approves CI/CD secret injection |
| **Mobile Dev** | Uses keystore only via local `key.properties` or CI secrets; never commits files |
| **Backup custodian** | Secondary encrypted copy (see Backup below) |

Minimum: **two people** must know backup recovery procedure; **passwords and keystore must not** live in email, chat, or the git repo.

---

## Backup procedure (required before first Play upload)

1. Copy `upload-keystore.jks` to encrypted offline storage (gov-approved vault, encrypted USB, or secrets manager export).
2. Copy `key.properties` separately (different storage container from the `.jks` file).
3. Record in internal release register:
   - Creation date
   - Alias
   - SHA-256 certificate fingerprint (`keytool -list -v -keystore upload-keystore.jks -alias smart-rajasthan-upload`)
   - Custodian names
4. Verify restore: copy backup to a clean machine and run `flutter build appbundle --release` after activity 1.8 is complete.

**Retention:** Keep all backups for the lifetime of app updates on Play Store. **Loss of this keystore prevents updating the existing listing.**

---

## Recovery

| Scenario | Action |
|----------|--------|
| Lost `key.properties` only | Restore from backup; or reset key password via `keytool` if store password is known |
| Lost keystore | Restore `.jks` from backup |
| Compromised keystore | Rotate keys (new keystore + new Play listing or Google key upgrade request); treat as security incident |
| New Release Owner | Secure handover of backup + password split; update custody register |

---

## CI / build machine usage

For automated builds, inject these environment variables or a generated `key.properties` from your secrets manager:

- `storePassword`
- `keyPassword`
- `keyAlias` = `smart-rajasthan-upload`
- `storeFile` path to the `.jks` file

Do **not** log secret values in build output.

---

## Verification checklist (Activity 1.7)

- [x] `generate_release_keystore.ps1` executed successfully (2026-06-27)
- [x] `android/keystore/upload-keystore.jks` exists locally
- [x] `android/key.properties` exists locally (not staged in git)
- [ ] Encrypted backup stored with secondary custodian
- [ ] Certificate fingerprint recorded in release register
- [ ] Activity **1.8** — Gradle release signing configured

**Certificate fingerprint (SHA-256) for release register:**

`02:CC:ED:A3:A9:C6:61:79:C0:6E:5F:AF:9E:48:A4:C7:EC:BF:8F:D8:89:50:FD:A1:04:EF:6A:BC:90:46:AF:CD`

---

## Related plan tasks

| ID | Task |
|----|------|
| 1.8 | Configure release signing in `android/app/build.gradle.kts` |
| 1.10–1.11 | Build release APK / AAB with production keystore |
| 5.1 | Formal backup procedure sign-off |
| 5.8 | Internal test track upload (AAB) |
