param(
  [Parameter(Mandatory = $true)]
  [string]$Url,
  [string]$Name
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$mapFile = Join-Path $PSScriptRoot "skills-map.txt"

$match = [regex]::Match($Url, '^https://github\.com/(?<owner>[^/]+)/(?<repo>[^/]+)/tree/(?<ref>[^/]+)/(?<path>.+)$')
if (-not $match.Success) {
  Write-Error "Unsupported URL format. Expected https://github.com/<owner>/<repo>/tree/<ref>/<path>"
}

$owner = $match.Groups["owner"].Value
$repo = $match.Groups["repo"].Value
$ref = $match.Groups["ref"].Value
$skillPath = $match.Groups["path"].Value.Trim("/")

$repoUrl = "https://github.com/$owner/$repo.git"
$submoduleKey = "$owner-$repo"
$skillName = if ($Name) { $Name } else { Split-Path -Leaf $skillPath }

if (-not (Test-Path (Join-Path $repoRoot ".git"))) {
  Write-Error "Not a git repository root: $repoRoot"
}

$submoduleRelPath = $null
$submoduleName = $null
if (Test-Path (Join-Path $repoRoot ".gitmodules")) {
  $urlLines = git -C $repoRoot config -f .gitmodules --get-regexp '^submodule\..*\.url$' 2>$null
  foreach ($urlLine in $urlLines) {
    $parts = $urlLine -split '\s+', 2
    if ($parts.Length -ne 2) {
      continue
    }

    if ($parts[1] -eq $repoUrl) {
      $key = $parts[0]
      $name = $key -replace '^submodule\.', '' -replace '\.url$', ''
      $pathKey = "submodule.$name.path"
      $existingPath = git -C $repoRoot config -f .gitmodules --get $pathKey
      if ($LASTEXITCODE -eq 0 -and $existingPath) {
        $submoduleName = $name
        $submoduleRelPath = $existingPath.Trim()
        break
      }
    }
  }
}

if (-not $submoduleRelPath) {
  $submoduleName = $submoduleKey
  $submoduleRelPath = ".codex/skill-sources/$submoduleKey"
}

$submodulePath = Join-Path $repoRoot $submoduleRelPath
$sourceRel = "$submoduleRelPath/$skillPath".Replace("\", "/")
$sourcePath = Join-Path $repoRoot $sourceRel

if (-not (Test-Path $submodulePath)) {
  git -C $repoRoot submodule add --name $submoduleKey --branch $ref $repoUrl $submoduleRelPath
  if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to add submodule: $submoduleRelPath"
  }
}

git -C $repoRoot config -f .gitmodules "submodule.$submoduleName.branch" $ref
if ($LASTEXITCODE -ne 0) {
  Write-Error "Failed to set submodule branch: $submoduleName"
}

git -C $repoRoot submodule sync -- $submoduleRelPath
if ($LASTEXITCODE -ne 0) {
  Write-Error "Failed to sync submodule config: $submoduleRelPath"
}

git -C $repoRoot submodule update --init --remote $submoduleRelPath
if ($LASTEXITCODE -ne 0) {
  Write-Error "Failed to update submodule: $submoduleRelPath"
}

if (-not (Test-Path $sourcePath)) {
  Write-Error "Skill path not found in source repo: $sourceRel"
}

if (-not (Test-Path $mapFile)) {
  New-Item -ItemType File -Path $mapFile | Out-Null
}

$newEntry = "$skillName $sourceRel"
$updated = $false
$lines = Get-Content $mapFile -ErrorAction SilentlyContinue
$out = @()
foreach ($line in $lines) {
  $trim = $line.Trim()
  if ($trim.Length -eq 0 -or $trim.StartsWith("#")) {
    $out += $line
    continue
  }

  $parts = $trim -split '\s+', 2
  if ($parts[0] -eq $skillName) {
    $out += $newEntry
    $updated = $true
  }
  else {
    $out += $line
  }
}

if (-not $updated) {
  $out += $newEntry
}

Set-Content -Path $mapFile -Value $out

& (Join-Path $PSScriptRoot "sync-skills.ps1")

Write-Host "Added skill '$skillName' from $Url"
