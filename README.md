# SMART Rajasthan (Flutter — Android)

Citizen mobile app for **SMART** — Services Management with Artificial Intelligence and Real-Time system, Government of Rajasthan.

| | |
|---|---|
| **Application ID** | `smart.rajasthan.gov.in` |
| **Stack** | Flutter 3.x, Dio, secure storage, Raj SSO |
| **Backend** | `smart_backend_mono` (`/smart` context path) |
| **Plan** | [`tool/PRODUCTION_PROJECT_PLAN.md`](tool/PRODUCTION_PROJECT_PLAN.md) |

---

## Quick start

```powershell
cd smart_rajasthan-main
flutter pub get
flutter doctor
flutter run -d android
```

**Live UAT** (real APIs):

```powershell
flutter run -d android --dart-define=USE_MOCK=false --dart-define=SMART_ENV=uat
```

---

## Build commands

| Build | Command | Output |
|-------|---------|--------|
| Debug APK | `flutter build apk --debug` | `build/app/outputs/flutter-apk/app-debug.apk` |
| Release APK | `flutter build apk --release` | `build/app/outputs/flutter-apk/app-release.apk` |
| Release AAB (Play Store) | `flutter build appbundle --release` | `build/app/outputs/bundle/release/app-release.aab` |

Release signing requires `android/key.properties` and the upload keystore (see below).

**Full guide:** [`tool/BUILD.md`](tool/BUILD.md) — prerequisites, signing, verification, troubleshooting.

---

## Release signing

1. Generate keystore: `android/scripts/generate_release_keystore.ps1`
2. Copy `android/key.properties.example` → `android/key.properties`
3. Build: `flutter build appbundle --release`

Details: [`tool/KEYSTORE_CUSTODY.md`](tool/KEYSTORE_CUSTODY.md)

---

## Project layout

| Path | Purpose |
|------|---------|
| `lib/` | Flutter UI & services |
| `lib/config/env.dart` | UAT / prod API hosts (`--dart-define`) |
| `android/` | Gradle, signing, manifests |
| `tool/` | Production plan, SSO, build & QA docs |
| `test/` | Unit tests (API client, auth) |

---

## Documentation index

- [**BUILD.md**](tool/BUILD.md) — Android build pipeline (activities 1.9–1.11)
- [**PRODUCTION_PROJECT_PLAN.md**](tool/PRODUCTION_PROJECT_PLAN.md) — Phases 1–5
- [**MOBILE_SSO_DESIGN.md**](tool/MOBILE_SSO_DESIGN.md) — SSO & deep links
- [**KEYSTORE_CUSTODY.md**](tool/KEYSTORE_CUSTODY.md) — Release keystore
- [**FEATURE_QA_CHECKLIST.md**](tool/FEATURE_QA_CHECKLIST.md) — Per-screen QA
