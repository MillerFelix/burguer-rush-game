Add-Type -AssemblyName System.Drawing

$texDir = "c:\BurgerRush\burger-rush\assets\textures"
if (-not (Test-Path $texDir)) { New-Item -ItemType Directory -Force -Path $texDir | Out-Null }

# =========================================================================
# 1. RAW BACON STRIP TEXTURE (512x256)
# Striated meat and fat marbling
# =========================================================================
$bmp = New-Object System.Drawing.Bitmap(512, 256)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

# Fundo carne vermelha escura
$g.Clear([System.Drawing.Color]::FromArgb(255, 175, 38, 42))

$rand = New-Object System.Random(42)

# Desenha faixas horizontais orgânicas de carne e gordura
for ($x = 0; $x -lt 512; $x++) {
    for ($y = 0; $y -lt 256; $y++) {
        $normY = $y / 256.0
        $normX = $x / 512.0
        
        # Ondulação orgânica
        $wave = [Math]::Sin($normX * 12.0) * 0.08 + [Math]::Sin($normX * 25.0) * 0.03 + ($rand.NextDouble() - 0.5) * 0.03
        $yWarp = $normY + $wave

        # Padrão de faixas de carne (vermelho escuro / rubi / rosa) e gordura (marfim / creme)
        # Faixa 1 (borda topo): carne fina
        # Faixa 2: gordura marmorizada
        # Faixa 3: carne espessa central
        # Faixa 4: gordura secundária
        # Faixa 5: carne base
        
        $isFat = $false
        $fatIntensity = 0.0

        if ($yWarp -ge 0.18 -and $yWarp -le 0.38) {
            $fatIntensity = [Math]::Sin(($yWarp - 0.18) / 0.20 * [Math]::PI)
            if ($fatIntensity -gt 0.3) { $isFat = $true }
        }
        elseif ($yWarp -ge 0.65 -and $yWarp -le 0.82) {
            $fatIntensity = [Math]::Sin(($yWarp - 0.65) / 0.17 * [Math]::PI)
            if ($fatIntensity -gt 0.25) { $isFat = $true }
        }

        # Pequenas estrias de gordura marmorizada
        $noise = [Math]::Sin($normX * 45.0 + $normY * 15.0) * [Math]::Cos($normX * 20.0 - $normY * 30.0)
        if ($noise -gt 0.65 -and $yWarp -gt 0.1 -and $yWarp -lt 0.9) {
            $isFat = $true
            $fatIntensity = [Math]::Max($fatIntensity, 0.7)
        }

        if ($isFat) {
            $r = [Math]::Min(255, [int](245 + ($rand.NextDouble() - 0.5) * 15))
            $gCol = [Math]::Min(255, [int](232 + ($rand.NextDouble() - 0.5) * 18))
            $b = [Math]::Min(255, [int](215 + ($rand.NextDouble() - 0.5) * 20))
            $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $r, $gCol, $b))
        } else {
            # Variação de carne: vermelho profundo, rubi, tons escuros de músculo
            $meatGrade = [Math]::Sin($normY * 18.0 + $normX * 8.0) * 0.5 + 0.5
            $r = [int](165 + $meatGrade * 45 + ($rand.NextDouble() - 0.5) * 20)
            $gCol = [int](28 + $meatGrade * 22 + ($rand.NextDouble() - 0.5) * 12)
            $b = [int](32 + $meatGrade * 24 + ($rand.NextDouble() - 0.5) * 14)
            $r = [Math]::Max(0, [Math]::Min(255, $r))
            $gCol = [Math]::Max(0, [Math]::Min(255, $gCol))
            $b = [Math]::Max(0, [Math]::Min(255, $b))
            $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $r, $gCol, $b))
        }
    }
}

$bmp.Save("$texDir\bacon_strip_raw.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
$g.Dispose()

# =========================================================================
# 2. COOKED BACON STRIP TEXTURE (512x256)
# Caramelized, roasted mahogany meat and golden-amber crispy fat
# =========================================================================
$bmpCooked = New-Object System.Drawing.Bitmap(512, 256)
$gCooked = [System.Drawing.Graphics]::FromImage($bmpCooked)
$gCooked.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$gCooked.Clear([System.Drawing.Color]::FromArgb(255, 110, 32, 18))

for ($x = 0; $x -lt 512; $x++) {
    for ($y = 0; $y -lt 256; $y++) {
        $normY = $y / 256.0
        $normX = $x / 512.0
        
        $wave = [Math]::Sin($normX * 12.0) * 0.08 + [Math]::Sin($normX * 25.0) * 0.03 + ($rand.NextDouble() - 0.5) * 0.04
        $yWarp = $normY + $wave

        $isFat = $false
        $fatIntensity = 0.0

        if ($yWarp -ge 0.18 -and $yWarp -le 0.38) {
            $fatIntensity = [Math]::Sin(($yWarp - 0.18) / 0.20 * [Math]::PI)
            if ($fatIntensity -gt 0.3) { $isFat = $true }
        }
        elseif ($yWarp -ge 0.65 -and $yWarp -le 0.82) {
            $fatIntensity = [Math]::Sin(($yWarp - 0.65) / 0.17 * [Math]::PI)
            if ($fatIntensity -gt 0.25) { $isFat = $true }
        }

        $noise = [Math]::Sin($normX * 45.0 + $normY * 15.0) * [Math]::Cos($normX * 20.0 - $normY * 30.0)
        if ($noise -gt 0.65 -and $yWarp -gt 0.1 -and $yWarp -lt 0.9) {
            $isFat = $true
        }

        if ($isFat) {
            # Gordura frita dourada / âmbar / caramelo
            $r = [Math]::Min(255, [int](218 + ($rand.NextDouble() - 0.5) * 20))
            $gCol = [Math]::Min(255, [int](168 + ($rand.NextDouble() - 0.5) * 25))
            $b = [Math]::Min(255, [int](95 + ($rand.NextDouble() - 0.5) * 25))
            $bmpCooked.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $r, $gCol, $b))
        } else {
            # Carne grelhada / tostada / avermelhada escura com bordas crocantes
            $meatGrade = [Math]::Sin($normY * 18.0 + $normX * 8.0) * 0.5 + 0.5
            $r = [int](115 + $meatGrade * 45 + ($rand.NextDouble() - 0.5) * 20)
            $gCol = [int](24 + $meatGrade * 18 + ($rand.NextDouble() - 0.5) * 12)
            $b = [int](16 + $meatGrade * 14 + ($rand.NextDouble() - 0.5) * 10)
            $r = [Math]::Max(0, [Math]::Min(255, $r))
            $gCol = [Math]::Max(0, [Math]::Min(255, $gCol))
            $b = [Math]::Max(0, [Math]::Min(255, $b))
            $bmpCooked.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $r, $gCol, $b))
        }
    }
}

$bmpCooked.Save("$texDir\bacon_strip_cooked.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmpCooked.Dispose()
$gCooked.Dispose()

Write-Output "Bacon textures created successfully!"
