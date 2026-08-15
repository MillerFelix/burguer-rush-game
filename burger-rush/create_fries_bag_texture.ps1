Add-Type -AssemblyName System.Drawing

$assetsDir = "c:\BurgerRush\burger-rush\assets\textures"
if (-not (Test-Path $assetsDir)) {
    New-Item -ItemType Directory -Path $assetsDir -Force
}

function Save-Bitmap($bmp, $filename) {
    $path = Join-Path $assetsDir $filename
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "Created $filename"
}

$rand = New-Object System.Random(777)

# 1. FROZEN FRIES BAG (512x512)
$bmpBag = New-Object System.Drawing.Bitmap(512, 512)
$gBag = [System.Drawing.Graphics]::FromImage($bmpBag)
$gBag.Clear([System.Drawing.Color]::FromArgb(255, 235, 240, 248))

# Gradient blue top and bottom banners
$topBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 28, 72, 148))
$gBag.FillRectangle($topBrush, 0, 0, 512, 110)
$botBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 24, 60, 128))
$gBag.FillRectangle($botBrush, 0, 420, 512, 92)

# Golden stripes accent
$goldBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 235, 180, 40))
$gBag.FillRectangle($goldBrush, 0, 110, 512, 14)
$gBag.FillRectangle($goldBrush, 0, 406, 512, 14)

# Central graphic: window showing frozen cut potatoes
$winBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
$gBag.FillEllipse($winBrush, 96, 150, 320, 220)

$fryBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 242, 215, 130))
$fryShade = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 215, 175, 80))
for ($i = 0; $i -lt 32; $i++) {
    $fx = $rand.Next(120, 350)
    $fy = $rand.Next(180, 330)
    $fw = $rand.Next(45, 90)
    $fh = $rand.Next(12, 18)
    $rot = $rand.Next(-35, 35)
    
    $state = $gBag.Save()
    $gBag.TranslateTransform($fx, $fy)
    $gBag.RotateTransform($rot)
    $gBag.FillRectangle($fryShade, -($fw/2)+2, -($fh/2)+2, $fw, $fh)
    $gBag.FillRectangle($fryBrush, -($fw/2), -($fh/2), $fw, $fh)
    $gBag.Restore($state)
}

# Add text elements
$fontTitle = New-Object System.Drawing.Font("Arial", 22, [System.Drawing.FontStyle]::Bold)
$fontSub = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
$whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$blueBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 20, 50, 110))

$gBag.DrawString("FROZEN FRIES", $fontTitle, $whiteBrush, 140, 35)
$gBag.DrawString("BATATA CONGELADA", $fontSub, $goldBrush, 145, 75)
$gBag.DrawString("PREMIUM CUT - 2.5 KG", $fontSub, $whiteBrush, 135, 450)

$gBag.Dispose()
Save-Bitmap $bmpBag "frozen_fries_bag.png"

# 2. VIBRANT DEEP RED TOMATO (512x512)
$bmpTomato = New-Object System.Drawing.Bitmap(512, 512)
for ($y = 0; $y -lt 512; $y++) {
    for ($x = 0; $x -lt 512; $x++) {
        $dx = ($x - 256.0) / 240.0
        $dy = ($y - 256.0) / 240.0
        $dist = [Math]::Sqrt($dx*$dx + $dy*$dy)
        $angle = [Math]::Atan2($dy, $dx)
        $noise = ($rand.Next(0, 14) - 7)
        
        if ($dist -gt 1.0) {
            $r = 215; $g = 20; $b = 15
        } elseif ($dist -gt 0.84) {
            # Bright crimson skin
            $r = 240; $g = 22; $b = 18
        } elseif ($dist -gt 0.32) {
            $spoke = [Math]::Cos($angle * 5.0)
            if ($spoke -gt 0.35) {
                # Thick fleshy septum
                $r = 230; $g = 35; $b = 25
            } else {
                # Juicy seed locule with golden seeds
                $seedDist = [Math]::Abs($dist - 0.58)
                if ($seedDist -lt 0.09 -and $rand.Next(0, 10) -gt 5) {
                    $r = 245; $g = 205; $b = 50
                } else {
                    $r = 190; $g = 20; $b = 20
                }
            }
        } else {
            # Center core
            $r = 235; $g = 35; $b = 25
        }
        $r = [Math]::Max(0, [Math]::Min(255, $r + $noise))
        $g = [Math]::Max(0, [Math]::Min(255, $g + $noise))
        $b = [Math]::Max(0, [Math]::Min(255, $b + $noise))
        $bmpTomato.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $r, $g, $b))
    }
}
Save-Bitmap $bmpTomato "veg_tomato_bright.png"
