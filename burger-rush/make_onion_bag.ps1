Add-Type -AssemblyName System.Drawing

$bmp = New-Object System.Drawing.Bitmap(512, 512)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

# 1. Base Transparent / Translucent Bag Background (Frosted Plastic)
$bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 245, 240, 245))
$g.FillRectangle($bgBrush, 0, 0, 512, 512)

# Top & Bottom Heat-Sealed Plastic Crimps (Darker translucent purple/burgundy / frost)
$crimpBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 110, 30, 80))
$g.FillRectangle($crimpBrush, 0, 0, 512, 60)
$g.FillRectangle($crimpBrush, 0, 452, 512, 60)

# Heat seal lines
$sealPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 160, 60, 130), [float]2.0)
for ($x = 10; $x -lt 512; $x += 16) {
    $g.DrawLine($sealPen, $x, 5, $x, 55)
    $g.DrawLine($sealPen, $x, 457, $x, 507)
}

# Gold / Amber accent stripes
$goldBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 235, 170, 40))
$g.FillRectangle($goldBrush, 0, 60, 512, 10)
$g.FillRectangle($goldBrush, 0, 442, 512, 10)

# 2. Large Central Transparent Window showing Real Onion Rings Inside
$winBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 250, 248, 252))
$g.FillRectangle($winBrush, 24, 80, 464, 352)

# Inner soft shadow for window depth
$winBorderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 200, 185, 205), [float]3.0)
$g.DrawRectangle($winBorderPen, 24, 80, 464, 352)

# Onion Rings (Golden battered crispy onion rings)
$rand = New-Object System.Random(4242)
$ringColors = @(
    [System.Drawing.Color]::FromArgb(255, 235, 180, 75),
    [System.Drawing.Color]::FromArgb(255, 245, 195, 95),
    [System.Drawing.Color]::FromArgb(255, 220, 160, 55),
    [System.Drawing.Color]::FromArgb(255, 240, 185, 80)
)
$ringDark = [System.Drawing.Color]::FromArgb(255, 175, 115, 30)

# Draw onion rings visible inside
for ($i = 0; $i -lt 36; $i++) {
    $cx = $rand.Next(60, 450)
    $cy = $rand.Next(100, 410)
    $radius = $rand.Next(28, 55)
    $thick = [float]$rand.Next(8, 14)
    $col = $ringColors[$rand.Next(0, $ringColors.Length)]
    
    # Shadow ring
    $shPen = New-Object System.Drawing.Pen($ringDark, ($thick + 2.0))
    $g.DrawEllipse($shPen, [float]($cx - $radius + 2), [float]($cy - $radius + 2), [float]($radius * 2), [float]($radius * 2))
    $shPen.Dispose()
    
    # Main ring body
    $rPen = New-Object System.Drawing.Pen($col, $thick)
    $g.DrawEllipse($rPen, [float]($cx - $radius), [float]($cy - $radius), [float]($radius * 2), [float]($radius * 2))
    $rPen.Dispose()
    
    # Inner onion ring texture (purple/white layer edge)
    $innerPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(160, 140, 40, 90), [float]2.0)
    $innerRad = [float]($radius - [int]($thick/2))
    $g.DrawEllipse($innerPen, ($cx - $innerRad), ($cy - $innerRad), ($innerRad * 2.0), ($innerRad * 2.0))
    $innerPen.Dispose()

    # Highlight arc
    $hlPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 255, 245, 190), [float]2.0)
    $g.DrawArc($hlPen, [float]($cx - $radius + 2), [float]($cy - $radius + 2), [float]($radius * 2 - 4), [float]($radius * 2 - 4), [float]180, [float]90)
    $hlPen.Dispose()
}

# 3. Clean Front Brand Badge (Centered, Beautiful, Professional Label)
$badgeRect = New-Object System.Drawing.Rectangle(76, 210, 360, 110)
$badgeBg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(245, 255, 255, 255))
$badgeBorder = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 110, 30, 80), [float]4.0)
$g.FillRectangle($badgeBg, $badgeRect)
$g.DrawRectangle($badgeBorder, $badgeRect)

# Inner gold line on badge
$innerGold = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 235, 170, 40), [float]2.0)
$g.DrawRectangle($innerGold, 82, 216, 348, 98)

# Brand texts
$fontMain = New-Object System.Drawing.Font("Impact", 28, [System.Drawing.FontStyle]::Regular)
$fontSub = New-Object System.Drawing.Font("Arial Black", 12, [System.Drawing.FontStyle]::Bold)

$purpleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 110, 30, 80))
$goldTextBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 190, 110, 15))

$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = [System.Drawing.StringAlignment]::Center
$sf.LineAlignment = [System.Drawing.StringAlignment]::Center

$g.DrawString("ANÉIS DE CEBOLA", $fontMain, $purpleBrush, [float]256, [float]250, $sf)
$g.DrawString("EMPANADA PARA FRITURA • PREMIUM", $fontSub, $goldTextBrush, [float]256, [float]288, $sf)

# Top banner text
$whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$fontBanner = New-Object System.Drawing.Font("Arial Black", 14, [System.Drawing.FontStyle]::Bold)
$g.DrawString("BURGER RUSH", $fontBanner, $whiteBrush, [float]256, [float]30, $sf)

# Bottom banner text
$fontBot = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$g.DrawString("CONTEÚDO: 2.0 KG • MANTER CONGELADO", $fontBot, $whiteBrush, [float]256, [float]482, $sf)

$destPath = "c:\BurgerRush\burger-rush\assets\textures\frozen_onion_bag.png"
$bmp.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
$g.Dispose()
Write-Host "Texture frozen_onion_bag.png generated successfully!"
