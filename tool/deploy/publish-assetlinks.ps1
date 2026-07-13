# Publish assetlinks.json to web servers (VAPT HIGH closure).
param(
    [ValidateSet('uat', 'prod', 'both')]
    [string]$Target = 'both',
    [string]$UatDeployPath = '',
    [string]$ProdDeployPath = ''
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $here '..\..\..\..\..')

$uatSource = Join-Path $here 'assetlinks-uat.json'
$prodSource = Join-Path $here 'assetlinks-prod.json'
$frontendPublic = Join-Path $repoRoot 'smart_frontend_web\smart_frontend\public\.well-known'

# Keep frontend static copies in sync.
$frontendDir = Join-Path $frontendPublic ''
if (Test-Path (Split-Path $frontendDir -Parent)) {
    Copy-Item $prodSource (Join-Path $frontendPublic 'assetlinks.json') -Force
    Copy-Item $uatSource (Join-Path $frontendPublic 'assetlinks-uat.json') -Force
    Write-Host "Synced -> smart_frontend/public/.well-known/"
}

function Deploy-File($source, $dest) {
    if ([string]::IsNullOrWhiteSpace($dest)) { return }
    $destDir = Split-Path $dest -Parent
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    Copy-Item $source $dest -Force
    Write-Host "Copied $source -> $dest"
}

if ($Target -eq 'uat' -or $Target -eq 'both') {
    Deploy-File $uatSource $UatDeployPath
    Write-Host ""
    Write-Host "UAT URL: https://smarttest.rajasthan.gov.in/.well-known/assetlinks.json"
    Get-Content $uatSource
}

if ($Target -eq 'prod' -or $Target -eq 'both') {
    Deploy-File $prodSource $ProdDeployPath
    Write-Host ""
    Write-Host "Prod URL: https://smart.rajasthan.gov.in/.well-known/assetlinks.json"
    Get-Content $prodSource
}

Write-Host ""
Write-Host "Verify (expect HTTP 200 + JSON):"
Write-Host "  Invoke-WebRequest https://smarttest.rajasthan.gov.in/.well-known/assetlinks.json"
Write-Host "  Invoke-WebRequest https://smart.rajasthan.gov.in/.well-known/assetlinks.json"
Write-Host ""
Write-Host "If using nginx, see tool/deploy/nginx-assetlinks.conf"
Write-Host "If using Next.js, redeploy frontend (route: app/.well-known/assetlinks.json/route.ts)"
