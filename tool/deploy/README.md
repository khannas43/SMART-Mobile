# Activity 3.2 — Infra deploy files

**VAPT (HIGH):** Android App Links require these files on the public web hosts before MobSF / VAPT closure.

Host these files for Android App Links verification (optional secondary callback URIs).

| Environment | Deploy path on web server | Source file |
|-------------|---------------------------|-------------|
| UAT | `https://smarttest.rajasthan.gov.in/.well-known/assetlinks.json` | `assetlinks-uat.json` |
| Production | `https://smart.rajasthan.gov.in/.well-known/assetlinks.json` | `assetlinks-prod.json` |

Copy from this folder:

- `assetlinks-uat.json` → UAT host (includes debug + release SHA-256 for QA builds)
- `assetlinks-prod.json` → Production host (release SHA-256 only)

Next.js static copies (deploy with web frontend):

- `smart_frontend/public/.well-known/assetlinks.json` (production static fallback)
- `smart_frontend/public/.well-known/assetlinks-uat.json` (UAT static fallback)
- **Preferred:** `smart_frontend/app/.well-known/assetlinks.json/route.ts` serves JSON at runtime
  (UAT when `NEXT_PUBLIC_DEPLOYMENT_ON=uat` or API URL contains `smarttest`)

After **web frontend redeploy**, verify:

```text
curl -s https://smarttest.rajasthan.gov.in/.well-known/assetlinks.json
curl -s https://smart.rajasthan.gov.in/.well-known/assetlinks.json
```

Full registration package: `tool/SSO_REDIRECT_URI_REGISTRATION.md`
