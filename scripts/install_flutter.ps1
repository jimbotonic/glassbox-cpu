<#
.SYNOPSIS
  Install the Flutter SDK on Windows and fetch this project's dependencies.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\install_flutter.ps1
  powershell -ExecutionPolicy Bypass -File scripts\install_flutter.ps1 -Dir D:\sdk\flutter -NoPath

.NOTES
  Can be run again safely: an existing SDK is upgraded instead of re-cloned.
  Requires Git for Windows (https://git-scm.com/download/win).
#>
param(
  # Where to put the SDK (default: $env:FLUTTER_HOME, or %USERPROFILE%\dev\flutter)
  [string]$Dir = $(if ($env:FLUTTER_HOME) { $env:FLUTTER_HOME } else { Join-Path $env:USERPROFILE 'dev\flutter' }),
  # Flutter channel to clone
  [ValidateSet('stable', 'beta')][string]$Channel = 'stable',
  # Do not add the SDK to the user PATH
  [switch]$NoPath
)

$ErrorActionPreference = 'Stop'
$ProjectDir = Split-Path -Parent $PSScriptRoot

function Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }

Step 'Checking required tools'
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  throw 'Git is required. Install it with: winget install --id Git.Git -e'
}

$flutterBat = Join-Path $Dir 'bin\flutter.bat'
if (Test-Path $flutterBat) {
  Step "Flutter already in $Dir, upgrading on channel $Channel"
  & $flutterBat channel $Channel
  & $flutterBat upgrade
} else {
  Step "Cloning Flutter ($Channel) into $Dir"
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Dir) | Out-Null
  # Full history on one branch: shallow clones break `flutter --version`.
  git clone --branch $Channel --single-branch https://github.com/flutter/flutter.git $Dir
  if ($LASTEXITCODE -ne 0) { throw 'git clone failed' }
}

$bin = Join-Path $Dir 'bin'
$env:Path = "$bin;$env:Path"

if (-not $NoPath) {
  Step "Adding $bin to the user PATH"
  $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  if (($userPath -split ';') -contains $bin) {
    Write-Host '  already there'
  } else {
    [Environment]::SetEnvironmentVariable('Path', ($(if ($userPath) { "$bin;$userPath" } else { $bin })), 'User')
    Write-Host '  added (open a new terminal to pick it up)'
  }
}

Step 'Downloading the Dart SDK and tools'
& flutter --disable-analytics | Out-Null
& flutter --version

Step 'Fetching project dependencies'
Push-Location $ProjectDir
try { & flutter pub get; if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' } }
finally { Pop-Location }

Step 'flutter doctor'
& flutter doctor

Write-Host @"

Flutter is installed in $Dir.
Open a new terminal, then:
  flutter test               # run the test suite
  flutter run -d windows     # run the desktop app (needs Visual Studio 'Desktop development with C++')
  flutter run -d chrome      # run the app in a browser
"@
