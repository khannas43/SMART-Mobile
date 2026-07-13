# SMART Rajasthan — Android build guide (Activity 1.12)

**Application ID:** `smart.rajasthan.gov.in`  
**Kotlin namespace:** `gov.rajasthan.smart`  
**Platform:** Android only (Flutter)

**Defaults:**
- **Debug / emulator** (`flutter run`) → **UAT** — `ssotest.rajasthan.gov.in` + `smarttest.rajasthan.gov.in`, live API
- **Release APK** (`flutter build apk --release`) → **prod** unless `--dart-define=SMART_ENV=uat`

Full production plan: [`tool/PRODUCTION_PROJECT_PLAN.md`](PRODUCTION_PROJECT_PLAN.md)

---

## Prerequisites

1. **Flutter SDK** — run `flutter doctor` and resolve Android toolchain / license issues (activity 1.1).
2. **Android SDK** — via Android Studio; set `sdk.dir` in `android/local.properties` if needed.
3. **JDK 17** — Gradle uses Android Studio JBR on this machine.
4. **Dependencies** — from project root: `flutter pub get`

---

## Production APK (your primary workflow)

```powershell
cd MobileApp/smart_rajasthan-main/smart_rajasthan-main

# Release APK — store / field testing (Raj SSO only, HTTPS only, no dev menus)
# VAPT: pass RAJ_SSO_MOBILE_KEY and RAJ_SSO_CLIENT_ID from secure CI secret; use --obfuscate for prod.
flutter build apk --release --dart-define=USE_MOCK=false --obfuscate --split-debug-info=build/symbols --dart-define=RAJ_SSO_MOBILE_KEY=<from Raj SSO team> --dart-define=RAJ_SSO_CLIENT_ID=<from Raj SSO team>

# Install on device
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

**App Links (`assetlinks.json`):** The APK bundles verification JSON at `assets/.well-known/assetlinks.json` (Android: `src/main/assets/.well-known/`). Gradle task `syncAssetLinksIntoApk` copies from `tool/deploy/` on each build. For UAT fingerprints: `flutter build apk --release ... --dart-define=SMART_ENV=uat` and add to `android/gradle.properties` or pass `-PSMART_ENV=uat` to Gradle.

MobSF still requires the **same JSON** hosted at `https://smart.rajasthan.gov.in/.well-known/assetlinks.json` — extract from APK or use `tool/deploy/publish-assetlinks.ps1` for web deploy.

**Play Store bundle:**

```powershell
flutter build appbundle --release --dart-define=USE_MOCK=false
```

---

## UAT release APK (field testing on device)

Same config as emulator debug defaults:

```powershell
flutter build apk --release --dart-define=USE_MOCK=false --dart-define=SMART_ENV=uat
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

- SSO: `https://ssotest.rajasthan.gov.in/signin?ru=SMART`
- API: `https://smarttest.rajasthan.gov.in/smart`

---

## Debug on device / emulator (UAT — matches UAT APK)

No extra flags required; debug builds default to UAT + live API:

```powershell
flutter run
```

Optional internal QA menus (connectivity, cutover) — debug builds only:

```powershell
flutter run --dart-define=SHOW_QA_TOOLS=true
```

Login screen shows only **Login with Raj SSO** in release builds. Sandbox JWT and UAT tools are hidden on production release APKs.

---

## Prod debug / local overrides

```powershell
# Live prod API + Raj SSO on device/emulator
flutter run --dart-define=SMART_ENV=prod

flutter run --dart-define=SMART_ENV=dev --dart-define=USE_MOCK=false
flutter run --dart-define=SMART_ENV=dev --dart-define=USE_MOCK=false --dart-define=SMART_API_HOST=http://192.168.1.10:8080
```

See `lib/config/env.dart` for all `--dart-define` options.

---

## Release signing (activities 1.7–1.8)

Release APK/AAB must be signed with the **upload keystore**, not the debug key.

| File | Purpose | In git? |
|------|---------|---------|
| `android/keystore/upload-keystore.jks` | Release keystore | **No** |
| `android/key.properties` | Passwords + alias | **No** |
| `android/key.properties.example` | Template | Yes |

**One-time setup:**

```powershell
Set-Location android\scripts
.\generate_release_keystore.ps1
```

Copy `android/key.properties.example` → `android/key.properties` and fill credentials.

Custody & backup: [`tool/KEYSTORE_CUSTODY.md`](KEYSTORE_CUSTODY.md)

If `key.properties` is missing, release builds fall back to **debug signing** (local dev only — not for Play Store).

---

## Verify signing

```powershell
& "$env:LOCALAPPDATA\Android\sdk\build-tools\36.0.0\apksigner.bat" verify --verbose build\app\outputs\flutter-apk\app-release.apk
```

SHA-256 fingerprints: `android\scripts\print_signing_fingerprints.ps1`

---

## Production checklist (before distributing APK)

- [ ] Built with `--dart-define=USE_MOCK=false` (release forces live API anyway)
- [ ] `SMART_ENV=prod` (default — do not pass `uat`)
- [ ] Release keystore signed (`key.properties` present)
- [ ] Raj SSO redirect URIs registered (activity 3.2)
- [ ] Test on **physical device** — prod SSO + deep link (`smartrajasthan://sso-callback`)
- [ ] No QA menu items visible on login screen

---

## Troubleshooting

### Kotlin incremental cache (Windows D: vs C: Pub cache)

```powershell
flutter clean
flutter pub get
flutter build apk --release --dart-define=USE_MOCK=false
```

### SSO “This site can’t be reached” on emulator (UAT)

UAT hosts resolve to **internal Rajasthan network IPs**, not the public internet:

| Host | Internal IP (Rajasthan DNS) |
|------|-----------------------------|
| `ssotest.rajasthan.gov.in` | `10.70.249.81` |
| `smarttest.rajasthan.gov.in` | `10.70.234.250` |

Your **desktop browser** works because Windows resolves these via Rajasthan DNS (`172.20.1.15`, `172.20.1.5`) or Chrome Secure DNS.

The **Android emulator** forwards DNS to your PC’s primary server (`172.20.1.1` on Ethernet), which **does not resolve** `*.rajasthan.gov.in` → Chrome Custom Tab shows “The site can’t be reached”.

**Verify (PowerShell):**

```powershell
# Fails — same as emulator
nslookup ssotest.rajasthan.gov.in 172.20.1.1

# Works — Rajasthan gov DNS
nslookup ssotest.rajasthan.gov.in 172.20.1.15

# Emulator can reach the IP once DNS is fixed
& "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe" shell ping -c 1 10.70.249.81
```

**Fix A — launch emulator with Rajasthan DNS (recommended):**

1. Close the running emulator.
2. Start it with gov DNS servers:

```powershell
& "$env:LOCALAPPDATA\Android\sdk\emulator\emulator.exe" -avd Medium_Phone -dns-server 172.20.1.15,172.20.1.5
```

3. In another terminal: `flutter run`

**Fix B — Windows hosts file (Admin Notepad on `C:\Windows\System32\drivers\etc\hosts`):**

```
10.70.249.81   ssotest.rajasthan.gov.in
10.70.234.250  smarttest.rajasthan.gov.in
```

Cold-boot the emulator after saving.

**Fix C — reorder PC DNS:** On your active adapter (Wi‑Fi or Ethernet), put `172.20.1.15` and `172.20.1.5` **above** `172.20.1.1`.

**Fix D — physical Android device:** Install the UAT APK on a phone on the same gov/office network; SSO works there when the device uses Rajasthan DNS.

SSO login cannot be fixed in app code — Chrome must resolve the hostname to reach the internal UAT servers.

### Clean rebuild

```powershell
flutter clean
flutter pub get
flutter build appbundle --release --dart-define=USE_MOCK=false
```

---

## Related docs

| Doc | Topic |
|-----|--------|
| [`tool/PRODUCTION_PROJECT_PLAN.md`](PRODUCTION_PROJECT_PLAN.md) | Full phase plan & gates |
| [`tool/MOBILE_SSO_DESIGN.md`](MOBILE_SSO_DESIGN.md) | SSO / deep link |
| [`tool/SSO_PROD_CUTOVER_CHECKLIST.md`](SSO_PROD_CUTOVER_CHECKLIST.md) | Prod cutover (3.12) |
