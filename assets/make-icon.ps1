# Builds assets/RedMode.ico: a glowing red crescent moon and stars on a near-black tile.
# Multi-size (16..256) PNG-in-ICO so it stays crisp at every desktop zoom level.
#
#   powershell -ExecutionPolicy Bypass -File assets\make-icon.ps1 [-PreviewPng path.png]

param([string]$PreviewPng)

Add-Type -AssemblyName System.Drawing
$out = Join-Path $PSScriptRoot 'RedMode.ico'

function New-RoundRect([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

function Add-Sparkle($g, $brush, [float]$cx, [float]$cy, [float]$r) {
    # Four-point star
    $t = $r * 0.28
    $pts = [System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new($cx, $cy - $r),
        [System.Drawing.PointF]::new($cx + $t, $cy - $t),
        [System.Drawing.PointF]::new($cx + $r, $cy),
        [System.Drawing.PointF]::new($cx + $t, $cy + $t),
        [System.Drawing.PointF]::new($cx, $cy + $r),
        [System.Drawing.PointF]::new($cx - $t, $cy + $t),
        [System.Drawing.PointF]::new($cx - $r, $cy),
        [System.Drawing.PointF]::new($cx - $t, $cy - $t))
    $g.FillPolygon($brush, $pts)
}

function Draw-Icon([int]$s) {
    $bmp = New-Object System.Drawing.Bitmap $s, $s, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.Clear([System.Drawing.Color]::Transparent)
    $k = $s / 256.0

    # Tile: deep black-red gradient with a thin red rim
    $tile = New-RoundRect (6*$k) (6*$k) (244*$k) (244*$k) (52*$k)
    $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush ([System.Drawing.PointF]::new(0,0)), ([System.Drawing.PointF]::new($s,$s)), ([System.Drawing.Color]::FromArgb(255,34,4,4)), ([System.Drawing.Color]::FromArgb(255,6,0,0))
    $g.FillPath($bg, $tile)

    # Soft red glow behind the moon (skipped at tiny sizes where it just looks muddy)
    $mx = 116*$k; $my = 136*$k; $mr = 74*$k
    if ($s -ge 32) {
        $g.SetClip($tile)
        $glowR = $mr * 1.9
        $glowPath = New-Object System.Drawing.Drawing2D.GraphicsPath
        $glowPath.AddEllipse($mx-$glowR, $my-$glowR, 2*$glowR, 2*$glowR)
        $glow = New-Object System.Drawing.Drawing2D.PathGradientBrush $glowPath
        $glow.CenterColor = [System.Drawing.Color]::FromArgb(110,255,30,20)
        $glow.SurroundColors = [System.Drawing.Color[]]@([System.Drawing.Color]::FromArgb(0,255,0,0))
        $g.FillPath($glow, $glowPath)
        $g.ResetClip()
    }

    # Crescent moon: big circle minus an offset circle
    $moon = New-Object System.Drawing.Drawing2D.GraphicsPath
    $moon.AddEllipse($mx-$mr, $my-$mr, 2*$mr, 2*$mr)
    $bite = New-Object System.Drawing.Drawing2D.GraphicsPath
    $cr = $mr * 0.86
    $bite.AddEllipse(($mx + 40*$k) - $cr, ($my - 30*$k) - $cr, 2*$cr, 2*$cr)
    $region = New-Object System.Drawing.Region $moon
    $region.Exclude($bite)
    $moonBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush ([System.Drawing.PointF]::new($mx-$mr,$my-$mr)), ([System.Drawing.PointF]::new($mx+$mr,$my+$mr)), ([System.Drawing.Color]::FromArgb(255,255,90,70)), ([System.Drawing.Color]::FromArgb(255,200,0,0))
    $g.FillRegion($moonBrush, $region)

    # Stars
    $star = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,255,70,55))
    Add-Sparkle $g $star (188*$k) (74*$k) ([Math]::Max(2, 26*$k))
    if ($s -ge 24) { Add-Sparkle $g $star (206*$k) (138*$k) ([Math]::Max(1.5, 13*$k)) }
    if ($s -ge 48) { Add-Sparkle $g $star (150*$k) (46*$k)  (9*$k) }

    # Rim
    $g.DrawPath((New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255,120,12,8)), ([Math]::Max(1, 6*$k))), $tile)

    $g.Dispose()
    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    return ,$ms.ToArray()
}

$sizes = 16, 24, 32, 48, 64, 128, 256
$pngs = foreach ($s in $sizes) { ,(Draw-Icon $s) }

$fs = [System.IO.File]::Create($out)
$bw = New-Object System.IO.BinaryWriter $fs
$bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]$sizes.Count)
$offset = 6 + 16 * $sizes.Count
for ($i = 0; $i -lt $sizes.Count; $i++) {
    $s = $sizes[$i]; $len = $pngs[$i].Length
    $bw.Write([byte]($s % 256)); $bw.Write([byte]($s % 256))   # 256 is stored as 0
    $bw.Write([byte]0); $bw.Write([byte]0)
    $bw.Write([uint16]1); $bw.Write([uint16]32)
    $bw.Write([uint32]$len); $bw.Write([uint32]$offset)
    $offset += $len
}
foreach ($p in $pngs) { $bw.Write($p) }
$bw.Close()

if ($PreviewPng) { [System.IO.File]::WriteAllBytes($PreviewPng, $pngs[-1]) }
"Icon written: $out"
