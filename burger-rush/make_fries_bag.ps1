Add-Type -AssemblyName System.Drawing

$bmp = New-Object System.Drawing.Bitmap(512, 512)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

# 1. Base Transparent / Translucent Bag Background (Frosted Plastic)
$bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 230, 240, 250))
$g.FillRectangle($bgBrush, 0, 0, 512, 512)

# Top & Bottom Heat-Sealed Plastic Crimps (Darker translucent blue / frost)
$crimpBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 20, 60, 130))
$g.FillRectangle($crimpBrush, 0, 0, 512, 60)
$g.FillRectangle($crimpBrush, 0, 452, 512, 60)

# Heat seal lines
$sealPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 60, 120, 210), 2)
for ($x = 10; $x -lt 512; $x += 16) {
    $g.DrawLine($sealPen, $x, 5, $x, 55)
    $g.DrawLine($sealPen, $x, 457, $x, 507)
}

# Gold accent stripes
$goldBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 245, 190, 30))
$g.FillRectangle($goldBrush, 0, 60, 512, 10)
$g.FillRectangle($goldBrush, 0, 442, 512, 10)

# 2. Large Central Transparent Window showing Real French Fries Inside
$winBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 245, 250, 255))
$g.FillRectangle($winBrush, 24, 80, 464, 352)

# Inner soft shadow for window depth
$winBorderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 180, 205, 230), 3)
$g.DrawRectangle($winBorderPen, 24, 80, 464, 352)

# French Fries Sticks (Realistic golden-yellow fries)
$rand = New-Object System.Random(888)
$fryColors = @(
    [System.Drawing.Color]::FromArgb(255, 245, 210, 110),
    [System.Drawing.Color]::FromArgb(255, 238, 195, 85),
    [System.Drawing.Color]::FromArgb(255, 250, 220, 130),
    [System.Drawing.Color]::FromArgb(255, 225, 175, 65)
)
$fryDark = [System.Drawing.Color]::FromArgb(255, 195, 140, 40)

# Draw a cluster of french fries visible inside
for ($i = 0; $i -lt 50; $i++) {
    $fx = $rand.Next(50, 460)
    $fy = $rand.Next(100, 420)
    $fw = $rand.Next(65, 120)
    $fh = $rand.Next(14, 20)
    $rot = $rand.Next(-40, 40)
    $col = $fryColors[$rand.Next(0, $fryColors.Length)]
    
    $state = $g.Save()
    $g.TranslateTransform($fx, $fy)
    $g.RotateTransform($rot)
    
    # Fry Shadow / edge
    $shBrush = New-Object System.Drawing.SolidBrush($fryDark)
    $g.FillRectangle($shBrush, -($fw/2)+2, -($fh/2)+2, $fw, $fh)
    $shBrush.Dispose()
    
    # Fry Body
    $fBrush = New-Object System.Drawing.SolidBrush($col)
    $g.FillRectangle($fBrush, -($fw/2), -($fh/2), $fw, $fh)
    $fBrush.Dispose()
    
    # Fry Highlights
    $hlPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 255, 245, 180), 2)
    $g.DrawLine($hlPen, -($fw/2)+4, -($fh/2)+3, ($fw/2)-4, -($fh/2)+3)
    $hlPen.Dispose()
    
    $g.Restore($state)
}

# 3. Clean Front Brand Badge (Centered, Beautiful, Professional Label)
# Solid white/cream background badge with dark navy border & gold accents
$badgeRect = New-Object System.Drawing.Rectangle(76, 210, 360, 110)
$badgeBg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(245, 255, 255, 255))
$badgeBorder = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 20, 60, 130), 4)
$g.FillRectangle($badgeBg, $badgeRect)
$g.DrawRectangle($badgeBorder, $badgeRect)

# Inner gold line on badge
$innerGold = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 245, 190, 30), 2)
$g.DrawRectangle($innerGold, 82, 216, 348, 98)

# Brand texts
$fontMain = New-Object System.Drawing.Font("Impact", 28, [System.Drawing.FontStyle]::Regular)
$fontSub = New-Object System.Drawing.Font("Arial Black", 12, [System.Drawing.FontStyle]::Bold)

$navyBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 20, 50, 120))
$redBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 220, 30, 30))

$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = [System.Drawing.StringAlignment]::Center
$sf.LineAlignment = [System.Drawing.StringAlignment]::Center

$g.DrawString("BATATA FRITA", $fontMain, $redBrush, 256, 250, $sf)
$g.DrawString("PALITO CONGELADA • PREMIUM", $fontSub, $navyBrush, 256, 288, $sf)

# Top banner text
$whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$fontBanner = New-Object System.Drawing.Font("Arial Black", 14, [System.Drawing.FontStyle]::Bold)
$g.DrawString("BURGER RUSH", $fontBanner, $whiteBrush, 256, 30, $sf)

# Bottom banner text
$fontBot = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$g.DrawString("CONTEÚDO: 2.5 KG • MANTER CONGELADO", $fontBot, $whiteBrush, 256, 482, $sf)

$destPath = "c:\BurgerRush\burger-rush\assets\textures\frozen_fries_bag.png"
$bmp.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
$g.Dispose()
Write-Host "Texture frozen_fries_bag.png updated successfully!"
