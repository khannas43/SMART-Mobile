# Activity 1.7 — Generate SMART Rajasthan Android release keystore.
# Run once from repo root or this script's directory by the Release Owner.
# Output (gitignored): android/keystore/upload-keystore.jks, android/key.properties

$ErrorActionPreference = 'Stop'

$androidDir = Split-Path $PSScriptRoot -Parent
$keystoreDir = Join-Path $androidDir 'keystore'
$keystorePath = Join-Path $keystoreDir 'upload-keystore.jks'
$keyPropsPath = Join-Path $androidDir 'key.properties'
$alias = 'smart-rajasthan-upload'
$validityDays = 10000

function Resolve-Keytool {
    $cmd = Get-Command keytool -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $candidates = @(
        'C:\Program Files\Java\jdk-17\bin\keytool.exe',
        'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe'
    )
    if ($env:JAVA_HOME) {
        $candidates = @((Join-Path $env:JAVA_HOME 'bin\keytool.exe')) + $candidates
    }
    foreach ($path in $candidates) {
        if ($path -and (Test-Path $path)) { return $path }
    }
    throw 'keytool not found. Install JDK 17+ or Android Studio and ensure keytool is on PATH.'
}

$keytool = Resolve-Keytool

function New-SecurePassword {
    $bytes = New-Object byte[] 24
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    [Convert]::ToBase64String($bytes)
}

if (Test-Path $keystorePath) {
    Write-Error "Keystore already exists at $keystorePath. Delete it first only if intentionally rotating keys."
}

Write-Host 'Generating release keystore (PKCS12, RSA 2048)...'
New-Item -ItemType Directory -Force -Path $keystoreDir | Out-Null

$storePass = New-SecurePassword
# PKCS12 keystores use a single password for store and key.
$keyPass = $storePass
$dname = 'CN=SMART Rajasthan, OU=Department of Information Technology and Communications, O=Government of Rajasthan, L=Jaipur, ST=Rajasthan, C=IN'

& $keytool -genkeypair -v `
    -storetype PKCS12 `
    -keystore $keystorePath `
    -alias $alias `
    -keyalg RSA `
    -keysize 2048 `
    -validity $validityDays `
    -storepass $storePass `
    -keypass $keyPass `
    -dname $dname

@(
    "storePassword=$storePass"
    "keyPassword=$keyPass"
    "keyAlias=$alias"
    'storeFile=keystore/upload-keystore.jks'
) | Set-Content -Path $keyPropsPath -Encoding Ascii

Write-Host ''
Write-Host 'Release keystore created successfully.'
Write-Host "  Keystore : $keystorePath"
Write-Host "  Alias    : $alias"
Write-Host "  Validity : $validityDays days"
Write-Host "  Secrets  : $keyPropsPath (local only - never commit)"
Write-Host ''
Write-Host 'Next: back up the keystore and key.properties per tool/KEYSTORE_CUSTODY.md, then run activity 1.8.'
