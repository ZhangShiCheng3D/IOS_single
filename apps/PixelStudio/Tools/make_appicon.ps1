# Generates a 1024x1024 pixel-art AppIcon for PixelStudio using the in-app lospec16 palette.
# Pure System.Drawing, nearest-neighbor blocky cells so the icon itself looks like pixel art.
param(
    [string]$OutPath = "$PSScriptRoot\..\Assets.xcassets\AppIcon.appiconset\AppIcon-1024.png"
)

Add-Type -AssemblyName System.Drawing

$grid = 32          # logical pixel grid
$cell = 32          # device px per logical pixel -> 1024x1024
$size = $grid * $cell

$bmp = New-Object System.Drawing.Bitmap $size, $size
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor

function C([int]$r,[int]$g2,[int]$b) { [System.Drawing.Color]::FromArgb(255,$r,$g2,$b) }

# lospec16-derived palette
$skyTop   = C 0x29 0x36 0x6F   # deep indigo
$skyMid   = C 0x3B 0x5D 0xC9   # royal blue
$skyLow   = C 0x41 0xA6 0xF6   # azure (accent)
$sun      = C 0xFF 0xCD 0x75   # warm yellow
$sunCore  = C 0xEF 0x7D 0x57   # orange
$hillBack = C 0x25 0x71 0x79   # teal
$hillFront= C 0x38 0xB7 0x64   # green
$snow     = C 0xF4 0xF4 0xF4   # off-white

function Fill([int]$x,[int]$y,$color) {
    $b = New-Object System.Drawing.SolidBrush $color
    $g.FillRectangle($b, $x*$cell, $y*$cell, $cell, $cell)
    $b.Dispose()
}

# 1) Sky gradient (banded for pixel feel)
for ($y = 0; $y -lt $grid; $y++) {
    if ($y -lt 11) { $col = $skyTop }
    elseif ($y -lt 18) { $col = $skyMid }
    else { $col = $skyLow }
    for ($x = 0; $x -lt $grid; $x++) { Fill $x $y $col }
}

# 2) Sun (top-right), blocky circle
$cx = 23; $cy = 8; $rad = 4
for ($y = 0; $y -lt $grid; $y++) {
    for ($x = 0; $x -lt $grid; $x++) {
        $d = [Math]::Sqrt([Math]::Pow($x-$cx,2) + [Math]::Pow($y-$cy,2))
        if ($d -le $rad) {
            if ($d -le ($rad-2)) { Fill $x $y $sunCore } else { Fill $x $y $sun }
        }
    }
}

# 3) Back hill
for ($x = 0; $x -lt $grid; $x++) {
    $h = [int](20 + 5*[Math]::Sin($x/4.0))
    for ($y = $h; $y -lt $grid; $y++) { Fill $x $y $hillBack }
}

# 4) Front hill (taller, foreground) with a one-pixel highlight ridge
for ($x = 0; $x -lt $grid; $x++) {
    $h = [int](24 + 4*[Math]::Sin(($x+6)/5.0))
    Fill $x $h $snow                                   # sunlit ridge line
    for ($y = $h+1; $y -lt $grid; $y++) { Fill $x $y $hillFront }
}

$g.Dispose()

$dir = Split-Path $OutPath
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

# Flatten to 24bpp RGB (no alpha) — App Store rejects icons containing transparency.
$rect = New-Object System.Drawing.Rectangle 0, 0, $size, $size
$opaque = $bmp.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$opaque.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
$opaque.Dispose()
$bmp.Dispose()
Write-Output "Wrote $OutPath ($size x $size, 24bpp RGB)"
