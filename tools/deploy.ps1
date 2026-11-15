# Copies VATS's scripts into the game: r6\scripts\VATS. Checks them first (check-scripts.ps1).
# Ask the owner before running it, with the game closed: the scripts are compiled at the game's start.
#
#   .\tools\deploy.ps1 [-GameDir <game folder>]

param([string]$GameDir = 'E:\SteamLibrary\steamapps\common\Cyberpunk 2077')
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot

if (Get-Process Cyberpunk2077 -ErrorAction SilentlyContinue) { throw 'The game is running: close it first' }
& (Join-Path $PSScriptRoot 'check-scripts.ps1') -GameDir $GameDir

$to = Join-Path $GameDir 'r6\scripts\VATS'
New-Item -ItemType Directory -Force $to | Out-Null
Get-ChildItem (Join-Path $repo 'scripts\VATS') -Filter *.reds | ForEach-Object {
  Copy-Item $_.FullName (Join-Path $to $_.Name) -Force
  Write-Host "Deployed $($_.Name) to $to"
}
