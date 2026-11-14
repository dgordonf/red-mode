# Builds Red Mode, installs it for the current user, and adds a Desktop icon + Ctrl+Alt+R hotkey.
# No admin rights needed. Everything goes in %LOCALAPPDATA%\RedMode.

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$dest = Join-Path $env:LOCALAPPDATA 'RedMode'
$exe  = Join-Path $dest 'RedMode.exe'

& (Join-Path $root 'build.ps1')

# If Red Mode is currently on, switch it off so the exe can be replaced.
if (Get-Process RedMode -ErrorAction SilentlyContinue) {
    if (Test-Path $exe) { Start-Process $exe; Start-Sleep -Milliseconds 1500 }
    Get-Process RedMode -ErrorAction SilentlyContinue | Stop-Process -Force
}

New-Item -ItemType Directory -Force $dest | Out-Null
Copy-Item (Join-Path $root 'bin\RedMode.exe') $exe -Force
Copy-Item (Join-Path $root 'assets\RedMode.ico') (Join-Path $dest 'RedMode.ico') -Force

$shell = New-Object -ComObject WScript.Shell

$desktopLnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Red Mode.lnk'
$lnk = $shell.CreateShortcut($desktopLnk)
$lnk.TargetPath   = $exe
$lnk.IconLocation = "$dest\RedMode.ico,0"
$lnk.Hotkey       = 'CTRL+ALT+R'
$lnk.Description  = 'Toggle red night-vision mode'
$lnk.Save()

$startLnk = Join-Path ([Environment]::GetFolderPath('Programs')) 'Red Mode.lnk'
$lnk = $shell.CreateShortcut($startLnk)
$lnk.TargetPath   = $exe
$lnk.IconLocation = "$dest\RedMode.ico,0"
$lnk.Description  = 'Toggle red night-vision mode'
$lnk.Save()

# Nudge Explorer to pick up the new icon
try { & "$env:WINDIR\System32\ie4uinit.exe" -show } catch {}

""
"Red Mode is installed."
"  Double-click 'Red Mode' on your Desktop (or press Ctrl+Alt+R) to toggle it."
