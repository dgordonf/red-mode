# Turns Red Mode off (if it's on) and removes everything install.ps1 added.

$dest = Join-Path $env:LOCALAPPDATA 'RedMode'
$exe  = Join-Path $dest 'RedMode.exe'

if (Get-Process RedMode -ErrorAction SilentlyContinue) {
    if (Test-Path $exe) { Start-Process $exe; Start-Sleep -Milliseconds 1500 }
    Get-Process RedMode -ErrorAction SilentlyContinue | Stop-Process -Force
}

Remove-Item (Join-Path ([Environment]::GetFolderPath('Desktop'))  'Red Mode.lnk') -ErrorAction SilentlyContinue
Remove-Item (Join-Path ([Environment]::GetFolderPath('Programs')) 'Red Mode.lnk') -ErrorAction SilentlyContinue
Remove-Item $dest -Recurse -Force -ErrorAction SilentlyContinue

"Red Mode has been removed."
