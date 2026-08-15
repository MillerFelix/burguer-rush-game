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

# 1. LETTUCE (512x512)
$bmpLettuce = New-Object System.Drawing.Bitmap(512, 512)
$rand = New-Object System.Random(42)
for ($y = 0; $y -lt 512; $y++) {
    for ($x = 0; $x -lt 512; $x++) {
        $dx = ($x - 256.0) / 256.0
        $dy = ($y - 256.0) / 256.0
        $dist = [Math]::Sqrt($dx*$dx + $dy*$dy)
        
        # Rib wave
        $wave = [Math]::Sin($x * 0.08) * [Math]::Cos($y * 0.08) * 15.0
        $noise = ($rand.Next(0, 30) - 15)
        
        $r = [Math]::Max(0, [Math]::Min(255, [int](65 + $wave*0.8 + $noise)))
        $g = [Math]::Max(0, [Math]::Min(255, [int](175 + $wave*1.5 + $noise + (1.0 - $dist)*20.0)))
        $b = [Math]::Max(0, [Math]::Min(255, [int](45 + $wave*0.6 + $noise)))
        
        # Leaf veins
        if ([Math]::Abs($x - 256) -lt 14) {
            $r = [int]($r * 1.3)
            $g = [int]($g * 1.2)
            $b = [int]($b * 1.3)
        }
        $r = [Math]::Min(255, $r)
        $g = [Math]::Min(255, $g)
        $b = [Math]::Min(255, $b)
        
        $bmpLettuce.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $r, $g, $b))
    }
}
Save-Bitmap $bmpLettuce "veg_lettuce.png"

# 2. TOMATO SLICE (512x512)
$bmpTomato = New-Object System.Drawing.Bitmap(512, 512)
for ($y = 0; $y -lt 512; $y++) {
    for ($x = 0; $x -lt 512; $x++) {
        $dx = ($x - 256.0) / 240.0
        $dy = ($y - 256.0) / 240.0
        $dist = [Math]::Sqrt($dx*$dx + $dy*$dy)
        $angle = [Math]::Atan2($dy, $dx)
        $noise = ($rand.Next(0, 16) - 8)
        
        if ($dist -gt 1.0) {
            # Outside skin rim
            $r = 210; $g = 35; $b = 30
        } elseif ($dist -gt 0.82) {
            # Thick red skin & outer pericarp
            $r = 230; $g = 40; $b = 35
        } elseif ($dist -gt 0.35) {
            # Seed cavities (locules) vs Septa walls
            $spoke = [Math]::Cos($angle * 5.0)
            if ($spoke -gt 0.4) {
                # Radial wall (fleshy)
                $r = 225; $g = 50; $b = 40
            } else {
                # Jelly / seed cavity (darker translucent red/yellow seeds)
                $seedDist = [Math]::Abs($dist - 0.58)
                if ($seedDist -lt 0.08 -and $rand.Next(0, 10) -gt 6) {
                    # Yellowish seed
                    $r = 230; $g = 190; $b = 60
                } else {
                    $r = 180; $g = 35; $b = 35
                }
            }
        } else {
            # Center columella
            $r = 225; $g = 55; $b = 45
        }
        
        $r = [Math]::Max(0, [Math]::Min(255, $r + $noise))
        $g = [Math]::Max(0, [Math]::Min(255, $g + $noise))
        $b = [Math]::Max(0, [Math]::Min(255, $b + $noise))
        $bmpTomato.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $r, $g, $b))
    }
}
Save-Bitmap $bmpTomato "veg_tomato.png"

# 3. RED ONION (512x512)
$bmpRedOnion = New-Object System.Drawing.Bitmap(512, 512)
for ($y = 0; $y -lt 512; $y++) {
    for ($x = 0; $x -lt 512; $x++) {
        $dx = ($x - 256.0) / 240.0
        $dy = ($y - 256.0) / 240.0
        $dist = [Math]::Sqrt($dx*$dx + $dy*$dy)
        $ring = [Math]::Sin($dist * 38.0)
        $noise = ($rand.Next(0, 14) - 7)
        
        if ($dist -gt 0.90) {
            # Deep purple-magenta outer ring
            $r = 145; $g = 25; $b = 75
        } elseif ($ring -gt 0.6) {
            # Purple boundary between rings
            $r = 185; $g = 45; $b = 95
        } else {
            # Crisp white/pale pink inner ring flesh
            $r = 245; $g = 232; $b = 238
        }
        
        $r = [Math]::Max(0, [Math]::Min(255, $r + $noise))
        $g = [Math]::Max(0, [Math]::Min(255, $g + $noise))
        $b = [Math]::Max(0, [Math]::Min(255, $b + $noise))
        $bmpRedOnion.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $r, $g, $b))
    }
}
Save-Bitmap $bmpRedOnion "veg_red_onion.png"

# 4. WHITE/YELLOW ONION (512x512)
$bmpOnion = New-Object System.Drawing.Bitmap(512, 512)
for ($y = 0; $y -lt 512; $y++) {
    for ($x = 0; $x -lt 512; $x++) {
        $dx = ($x - 256.0) / 240.0
        $dy = ($y - 256.0) / 240.0
        $dist = [Math]::Sqrt($dx*$dx + $dy*$dy)
        $ring = [Math]::Sin($dist * 38.0)
        $noise = ($rand.Next(0, 14) - 7)
        
        if ($dist -gt 0.90) {
            # Golden amber skin ring
            $r = 215; $g = 180; $b = 110
        } elseif ($ring -gt 0.6) {
            # Subtle pale yellow ring boundary
            $r = 235; $g = 225; $b = 185
        } else {
            # Crisp ivory-white inner ring flesh
            $r = 250; $g = 248; $b = 235
        }
        
        $r = [Math]::Max(0, [Math]::Min(255, $r + $noise))
        $g = [Math]::Max(0, [Math]::Min(255, $g + $noise))
        $b = [Math]::Max(0, [Math]::Min(255, $b + $noise))
        $bmpOnion.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $r, $g, $b))
    }
}
Save-Bitmap $bmpOnion "veg_onion.png"

# 5. DILL PICKLE (512x512)
$bmpPickle = New-Object System.Drawing.Bitmap(512, 512)
for ($y = 0; $y -lt 512; $y++) {
    for ($x = 0; $x -lt 512; $x++) {
        $dx = ($x - 256.0) / 240.0
        $dy = ($y - 256.0) / 240.0
        $dist = [Math]::Sqrt($dx*$dx + $dy*$dy)
        $crinkle = [Math]::Sin($x * 0.12) * 12.0
        $noise = ($rand.Next(0, 16) - 8)
        
        if ($dist -gt 0.88) {
            # Dark olive green cucumber skin
            $r = 55; $g = 95; $b = 35
        } elseif ($dist -gt 0.40) {
            # Crisp pickle flesh with crinkle ridges
            $r = 115 + [int]($crinkle*0.5); $g = 160 + [int]$crinkle; $b = 65 + [int]($crinkle*0.4)
        } else {
            # Pale translucent pickle seed core with dill seasoning dots
            if ($rand.Next(0, 100) -gt 92) {
                # Dark dill spice speckle
                $r = 30; $g = 45; $b = 18
            } else {
                $r = 135; $g = 175; $b = 85
            }
        }
        
        $r = [Math]::Max(0, [Math]::Min(255, $r + $noise))
        $g = [Math]::Max(0, [Math]::Min(255, $g + $noise))
        $b = [Math]::Max(0, [Math]::Min(255, $b + $noise))
        $bmpPickle.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $r, $g, $b))
    }
}
Save-Bitmap $bmpPickle "veg_pickle.png"

# 6. SHARED VEGETABLE NORMAL MAP (512x512)
$bmpNorm = New-Object System.Drawing.Bitmap(512, 512)
for ($y = 0; $y -lt 512; $y++) {
    for ($x = 0; $x -lt 512; $x++) {
        $nx = [int](128 + ($rand.Next(0, 20) - 10))
        $ny = [int](128 + ($rand.Next(0, 20) - 10))
        $nz = 255
        $bmpNorm.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $nx, $ny, $nz))
    }
}
Save-Bitmap $bmpNorm "veg_normal.png"
