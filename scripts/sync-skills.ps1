param()

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$mapFile = Join-Path $PSScriptRoot "skills-map.txt"

if (-not (Test-Path $mapFile)) {
  Write-Error "Missing skill map: $mapFile"
}

git -C $repoRoot submodule update --init --remote .codex/skill-sources/atlas-skills
if ($LASTEXITCODE -ne 0) {
  Write-Error "Failed to update atlas-skills source submodule"
}

$skillsDir = Join-Path $repoRoot ".codex/skills"
New-Item -ItemType Directory -Force -Path $skillsDir | Out-Null

Get-Content $mapFile | ForEach-Object {
  $line = $_.Trim()
  if ($line.Length -eq 0 -or $line.StartsWith("#")) {
    return
  }

  $parts = $line -split '\s+', 2
  if ($parts.Length -ne 2) {
    Write-Error "Invalid mapping line: $line"
  }

  $name = $parts[0]
  $sourceRel = $parts[1]
  $sourcePath = Join-Path $repoRoot $sourceRel
  $destPath = Join-Path $skillsDir $name

  if (-not (Test-Path $sourcePath)) {
    Write-Error "Source skill path not found: $sourcePath"
  }

  if (Test-Path $destPath) {
    Remove-Item -Path $destPath -Recurse -Force
  }

  try {
    New-Item -ItemType SymbolicLink -Path $destPath -Target $sourcePath | Out-Null
  }
  catch {
    New-Item -ItemType Junction -Path $destPath -Target $sourcePath | Out-Null
  }

  Write-Host "Linked $name -> $sourcePath"
}
