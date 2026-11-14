# Compiles src\RedMode.cs into bin\RedMode.exe using the C# compiler that ships with Windows.
# No Visual Studio or SDK needed.

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

$csc = @(
    "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
    "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\csc.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $csc) { throw "Couldn't find csc.exe (.NET Framework 4). It ships with Windows 10/11, so this is unusual." }

$icon = Join-Path $root 'assets\RedMode.ico'
if (-not (Test-Path $icon)) { & (Join-Path $root 'assets\make-icon.ps1') | Out-Null }

New-Item -ItemType Directory -Force (Join-Path $root 'bin') | Out-Null
$exe = Join-Path $root 'bin\RedMode.exe'

& $csc /nologo /target:winexe /optimize "/win32icon:$icon" "/out:$exe" (Join-Path $root 'src\RedMode.cs')
if ($LASTEXITCODE -ne 0) { throw "Build failed." }
"Built $exe"
