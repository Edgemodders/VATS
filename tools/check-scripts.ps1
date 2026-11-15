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

# The game's own compiler (engine\tools\scc.exe, redscript's) on a scratch copy of the game's layout
# in out\scc, with Codeware's scripts beside VATS's as in the game. It is stricter than this
# redscript-cli in places: it refused "private let m_partChance: Int32 = -1;" (a negative field
# default) that the CLI took (2026-11-14). Nothing is written next to the game's own files.
$scc = Join-Path $GameDir 'engine\tools\scc.exe'
if (Test-Path $scc) {
  $box = Join-Path $out 'scc'
  if (Test-Path $box) { Remove-Item -Recurse -Force $box }
  foreach ($d in 'engine\tools', 'r6\cache', 'r6\scripts', 'r6\logs') { New-Item -ItemType Directory -Force (Join-Path $box $d) | Out-Null }
  Copy-Item $scc, (Join-Path $GameDir 'engine\tools\scc_lib.dll') (Join-Path $box 'engine\tools') -Force
  # The game's own bundle: redscript keeps it as .bk once it has written the cache itself.
  $bk = Join-Path $GameDir 'r6\cache\final.redscripts.bk'
  Copy-Item ($(if (Test-Path $bk) { $bk } else { $bundle })) (Join-Path $box 'r6\cache\final.redscripts') -Force
  Copy-Item (Join-Path $src 'VATS') (Join-Path $box 'r6\scripts\VATS') -Recurse -Force
  if (Test-Path $codeware) { Copy-Item $codeware (Join-Path $box 'r6\scripts\Codeware') -Recurse -Force }
  & (Join-Path $box 'engine\tools\scc.exe') -compile (Join-Path $box 'r6\scripts') 2>&1 | Out-Null
  $log = Get-Content (Join-Path $box 'r6\logs\redscript_rCURRENT.log') -ErrorAction SilentlyContinue
  $errors = @($log | Select-String -CaseSensitive -Pattern '\[ERROR' -Context 0, 3)
  if ($errors.Count) {
    $errors | ForEach-Object { $_.ToString() } | Write-Host
    throw "The game's compiler: $($errors.Count) error(s)"
  }
  if (-not ($log | Select-String 'Compilation complete')) { throw "The game's compiler did not finish: see $box\r6\logs" }
  Write-Host "The game's compiler (scc.exe): 0 errors, beside Codeware"
} else {
  Write-Host "No engine\tools\scc.exe in the game folder: the game's compiler check skipped"
}
