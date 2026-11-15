# Compiles VATS's scripts against the game's own (r6\cache\final.redscripts), alone and beside
# Codeware's, and fails on any error in VATS's own files. One compile error in the game stops every
# script, so run this before every deploy.
#
#   .\tools\check-scripts.ps1 [-GameDir <game folder>] [-Cli <redscript-cli.exe>]
#
# This redscript-cli version reports errors in Codeware 1.21's own files that the game's compiler
# accepts, so only errors in VATS's files count.

param(
  [string]$GameDir = 'E:\SteamLibrary\steamapps\common\Cyberpunk 2077',
  [string]$Cli = 'E:\Modding\Tools\redscript-cli\redscript-cli.exe'
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$src = Join-Path $repo 'scripts'
$out = Join-Path $repo 'out'
New-Item -ItemType Directory -Force $out | Out-Null

$bundle = Join-Path $GameDir 'r6\cache\final.redscripts'
if (-not (Test-Path $bundle)) { throw "No game scripts at $bundle" }
if (-not (Test-Path $Cli)) { throw "No redscript-cli at $Cli (see REDnode's docs/dev-setup.md)" }
# The game's bundle is copied first: the CLI must never write next to the game's own.
$base = Join-Path $out 'base.redscripts'
Copy-Item $bundle $base -Force

function Check([string]$what, [string[]]$extra) {
  $cliArgs = @('compile', '-s', $src)
  foreach ($e in $extra) { $cliArgs += @('-s', $e) }
  $cliArgs += @('-b', $base, '-o', (Join-Path $out 'check.redscripts'))
  $lines = & $Cli @cliArgs 2>&1 | ForEach-Object { $_.ToString() }
  # The CLI tags each error "ERROR" in capitals (its summary line says "errors", which must not count).
  $mine = @($lines | Select-String -CaseSensitive -Pattern 'ERROR' -Context 0, 2 | Where-Object { $_.Line -match [regex]::Escape($src) })
  $all = @($lines | Select-String -CaseSensitive -Pattern 'ERROR').Count
  if ($mine.Count) {
    $mine | ForEach-Object { $_.ToString() } | Write-Host
    throw "$what`: $($mine.Count) error(s) in VATS's scripts"
  }
  Write-Host "$what`: 0 errors in VATS's scripts ($all in all)"
}

Check 'Alone' @()
$codeware = Join-Path $GameDir 'red4ext\plugins\Codeware\Scripts'
if (Test-Path $codeware) { Check 'Beside Codeware' @($codeware) } else { Write-Host 'Codeware not installed: that check skipped' }
