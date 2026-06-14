[CmdletBinding()]
param(
  [switch]$NoGitBash,
  [switch]$NoWsl
)

$ErrorActionPreference = "Stop"

function Write-Section {
  param([string]$Message)

  Write-Host ""
  Write-Host "==> $Message"
}

function Invoke-Native {
  param(
    [string]$Name,
    [string]$FilePath,
    [string[]]$ArgumentList
  )

  Write-Section $Name
  & $FilePath @ArgumentList
  $exitCode = $LASTEXITCODE

  if ($exitCode -ne 0) {
    throw "Command failed with exit code $exitCode`: $FilePath $($ArgumentList -join ' ')"
  }
}

function Get-GitBashPath {
  if ($NoGitBash) {
    return $null
  }

  $candidates = @()

  $pathCommands = Get-Command bash.exe -All -ErrorAction SilentlyContinue
  if ($pathCommands) {
    $candidates += $pathCommands | ForEach-Object { $_.Source }
  }

  $commonPaths = @(
    (Join-Path $env:ProgramFiles "Git\bin\bash.exe"),
    (Join-Path $env:ProgramFiles "Git\usr\bin\bash.exe")
  )

  if (${env:ProgramFiles(x86)}) {
    $commonPaths += @(
      (Join-Path ${env:ProgramFiles(x86)} "Git\bin\bash.exe"),
      (Join-Path ${env:ProgramFiles(x86)} "Git\usr\bin\bash.exe")
    )
  }

  if ($env:LOCALAPPDATA) {
    $commonPaths += @(
      (Join-Path $env:LOCALAPPDATA "Programs\Git\bin\bash.exe"),
      (Join-Path $env:LOCALAPPDATA "Programs\Git\usr\bin\bash.exe")
    )
  }

  $candidates += $commonPaths
  $candidates = $candidates | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique

  foreach ($candidate in $candidates) {
    $probe = & $candidate -lc 'command -v cygpath >/dev/null 2>&1 && uname -s' 2>$null
    if ($LASTEXITCODE -eq 0 -and ($probe -match "MINGW|MSYS")) {
      return $candidate
    }
  }

  return $null
}

function Test-WslBash {
  if ($NoWsl) {
    return $false
  }

  $wsl = Get-Command wsl.exe -ErrorAction SilentlyContinue
  if (-not $wsl) {
    return $false
  }

  try {
    $probe = & wsl.exe -e bash -lc 'printf ok' 2>$null
    $exitCode = $LASTEXITCODE
  } catch {
    return $false
  }

  return ($exitCode -eq 0 -and ($probe -eq "ok"))
}

function Convert-ToWslPath {
  param([string]$WindowsPath)

  $wslPath = & wsl.exe -e wslpath -a $WindowsPath
  if ($LASTEXITCODE -ne 0 -or -not $wslPath) {
    throw "Unable to convert repository path for WSL: $WindowsPath"
  }

  return $wslPath.Trim()
}

function Quote-BashSingle {
  param([string]$Value)

  return "'" + $Value.Replace("'", "'\''") + "'"
}

function Show-BashFallback {
  param([string]$RepoRoot)

  Write-Host ""
  Write-Host "Unable to run Bash checks locally: Git Bash was not found and WSL does not have a working Bash distro."
  Write-Host ""
  Write-Host "Install one local Bash path, then rerun from this repository:"
  Write-Host "  powershell -ExecutionPolicy Bypass -File .\scripts\preflight.ps1"
  Write-Host ""
  Write-Host "Supported local options:"
  Write-Host "  1. Install Git for Windows and make Git Bash available."
  Write-Host "  2. Install a WSL Linux distribution with bash available."
  Write-Host ""
  Write-Host "Manual fallback commands to run in any Bash-capable checkout:"
  Write-Host "  cd $RepoRoot"
  Write-Host "  git diff --check"
  Write-Host "  bash -n toolkit.sh install.sh"
  Write-Host "  bash -n modules/scripts_hub.sh"
  Write-Host "  bash tests/smoke_menu.sh"
  Write-Host ""
  Write-Host "If neither Git Bash nor WSL is available on this Windows machine, push the branch and rely on GitHub Actions. Include this note in the handoff: local Bash checks were skipped because Git Bash/WSL was unavailable."
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..")).Path

Write-Host "LuoPo VPS Toolkit preflight"
Write-Host "Repository: $repoRoot"

Invoke-Native "git diff --check" "git" @("-C", $repoRoot, "diff", "--check")

$bashCommands = 'set -euo pipefail; bash -n toolkit.sh install.sh; bash -n modules/scripts_hub.sh; bash tests/smoke_menu.sh'
$gitBash = Get-GitBashPath

if ($gitBash) {
  Write-Host ""
  Write-Host "Using Git Bash: $gitBash"
  Invoke-Native "Bash syntax and smoke checks" $gitBash @(
    "-lc",
    "set -euo pipefail; repo=`"$(cygpath -u `"`$1`")`"; cd `"`$repo`"; bash -n toolkit.sh install.sh; bash -n modules/scripts_hub.sh; bash tests/smoke_menu.sh",
    "--",
    $repoRoot
  )
  Write-Host ""
  Write-Host "Preflight passed."
  exit 0
}

if (Test-WslBash) {
  $wslRepoRoot = Convert-ToWslPath $repoRoot
  Write-Host ""
  Write-Host "Using WSL: $wslRepoRoot"
  Invoke-Native "Bash syntax and smoke checks" "wsl.exe" @(
    "-e",
    "bash",
    "-lc",
    "cd $(Quote-BashSingle $wslRepoRoot); $bashCommands"
  )
  Write-Host ""
  Write-Host "Preflight passed."
  exit 0
}

Show-BashFallback $repoRoot
exit 2
