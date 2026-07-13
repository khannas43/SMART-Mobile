# Activity 3.2 — Print SHA-256 fingerprints for Raj SSO / Android App Links registration.
# Run from repo root or this directory. Does not print keystore passwords.

$ErrorActionPreference = 'Stop'

$androidDir = Split-Path $PSScriptRoot -Parent
$keyPropsPath = Join-Path $androidDir 'key.properties'
$debugKeystore = Join-Path $env:USERPROFILE '.android\debug.keystore'

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
    throw 'keytool not found. Install JDK 17+ or Android Studio.'
}

function Show-Fingerprint {
    param(
        [string]$Label,
        [string]$KeystorePath,
        [string]$Alias,
        [string]$StorePass,
        [string]$KeyPass = $StorePass
    )
    if (-not (Test-Path $KeystorePath)) {
        Write-Host "$Label : (keystore not found at $KeystorePath)"
        return
    }
    Write-Host "=== $Label ==="
    Write-Host "  Keystore : $KeystorePath"
    Write-Host "  Alias    : $Alias"
    & $keytool -list -v `
        -keystore $KeystorePath `
        -alias $Alias `
        -storepass $StorePass `
        -keypass $KeyPass `
        | Select-String -Pattern 'SHA256:|SHA1:'
    Write-Host ''
}

$keytool = Resolve-Keytool

Write-Host 'SMART Rajasthan - signing certificate fingerprints (activity 3.2)'
Write-Host ''

Show-Fingerprint `
    -Label 'Debug (local / UAT device testing)' `
    -KeystorePath $debugKeystore `
    -Alias 'androiddebugkey' `
    -StorePass 'android'

if (Test-Path $keyPropsPath) {
    $props = @{}
    Get-Content $keyPropsPath | ForEach-Object {
        if ($_ -match '^\s*([^#=]+)=(.*)$') {
            $props[$matches[1].Trim()] = $matches[2].Trim()
        }
    }
    $storeFile = $props['storeFile']
    $storePath = if ($storeFile) { Join-Path $androidDir $storeFile } else { $null }
    if ($storePath -and (Test-Path $storePath) -and $props['storePassword'] -and $props['keyAlias']) {
        Show-Fingerprint `
            -Label 'Release (Play Store / production)' `
            -KeystorePath $storePath `
            -Alias $props['keyAlias'] `
            -StorePass $props['storePassword'] `
            -KeyPass $(if ($props['keyPassword']) { $props['keyPassword'] } else { $props['storePassword'] })
    } else {
        Write-Host 'Release keystore : not configured yet (activity 1.7).'
        Write-Host '  Run android/scripts/generate_release_keystore.ps1 then re-run this script.'
    }
} else {
    Write-Host 'Release keystore : key.properties missing (activity 1.7).'
}

Write-Host 'Paste SHA-256 values into tool/SSO_REDIRECT_URI_REGISTRATION.md before sending to Raj SSO team.'
