# Deploy Qt runtime next to EWR_Manager.exe for standalone double-click launch.
# Usage:
#   .\scripts\deploy.ps1
#   .\scripts\deploy.ps1 -ExePath "E:\path\to\EWR_Manager.exe"

param(
    [string]$ExePath = "",
    [string]$QtRoot = "C:\Qt\6.10.2\mingw_64",
    [string]$MingwBin = "C:\Qt\Tools\mingw1310_64\bin"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $QtRoot)) {
    throw "Qt not found at $QtRoot. Pass -QtRoot with your Qt install path."
}

$windeployqt = Join-Path $QtRoot "bin\windeployqt.exe"
if (-not (Test-Path $windeployqt)) {
    throw "windeployqt not found at $windeployqt"
}

if ($ExePath -eq "") {
    $candidates = @(
        (Join-Path $PSScriptRoot "..\build\EWR_Manager.exe"),
        (Join-Path $PSScriptRoot "..\build\Desktop_Qt_6_10_2_MinGW_64_bit-Debug\EWR_Manager.exe")
    )
    foreach ($c in $candidates) {
        $resolved = Resolve-Path $c -ErrorAction SilentlyContinue
        if ($resolved) {
            $ExePath = $resolved.Path
            break
        }
    }
}

if (-not (Test-Path $ExePath)) {
    throw "Executable not found: $ExePath. Build the project first or pass -ExePath."
}

$exeDir = Split-Path $ExePath -Parent
$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$qmlDir = Join-Path $projectRoot "qml"
$qtPlugins = Join-Path $QtRoot "plugins"

Write-Host "Deploying: $ExePath"

function Copy-PluginFolder {
    param([string]$Name)
    $src = Join-Path $qtPlugins $Name
    if (-not (Test-Path $src)) { return }
    $dst = Join-Path $exeDir $Name
    New-Item -ItemType Directory -Force -Path $dst | Out-Null
    Copy-Item (Join-Path $src "*") $dst -Force
}

$platformsDir = Join-Path $exeDir "platforms"
New-Item -ItemType Directory -Force -Path $platformsDir | Out-Null
Copy-Item (Join-Path $qtPlugins "platforms\qwindows.dll") $platformsDir -Force

$env:PATH = "$(Join-Path $QtRoot 'bin');$MingwBin;" + $env:PATH
$env:QT_PLUGIN_PATH = $qtPlugins

& $windeployqt --release --no-translations --qmldir $qmlDir $ExePath
if ($LASTEXITCODE -ne 0) {
    Write-Warning "windeployqt exited with code $LASTEXITCODE; copying essential plugins manually."
}

foreach ($folder in @("sqldrivers", "imageformats", "iconengines", "tls")) {
    Copy-PluginFolder $folder
}

$runtime = @("libgcc_s_seh-1.dll", "libstdc++-6.dll", "libwinpthread-1.dll")
foreach ($dll in $runtime) {
    Copy-Item (Join-Path $MingwBin $dll) $exeDir -Force
}

if (-not (Test-Path (Join-Path $exeDir "sqldrivers\qsqlite.dll"))) {
    throw "Missing sqldrivers/qsqlite.dll after deploy."
}

Write-Host "Done. You can double-click:"
Write-Host $ExePath
