param()

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot

git -C $repoRoot config core.hooksPath .githooks
if ($LASTEXITCODE -ne 0) {
  Write-Error "Failed to set core.hooksPath"
}

git -C $repoRoot submodule update --init --recursive
if ($LASTEXITCODE -ne 0) {
  Write-Error "Failed to initialize submodules"
}

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "sync-skills.ps1")
if ($LASTEXITCODE -ne 0) {
  Write-Error "Failed to sync skills"
}

Write-Host "Bootstrap complete"
