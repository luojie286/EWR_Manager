# Build (if needed), deploy Qt runtime, then launch EWR_Manager.
# Usage: powershell -ExecutionPolicy Bypass -File scripts\run.ps1

$ErrorActionPreference = "Stop"
$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

& (Join-Path $PSScriptRoot "deploy.ps1")

$exe = Get-ChildItem -Path (Join-Path $projectRoot "build") -Recurse -Filter "EWR_Manager.exe" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $exe) {
    throw "EWR_Manager.exe not found under build/. Build the project in Qt Creator first."
}

Write-Host "Starting $($exe.FullName)"
Start-Process -FilePath $exe.FullName -WorkingDirectory $exe.DirectoryName
