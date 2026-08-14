Add-Type -AssemblyName System.Drawing

$texDir = "c:\BurgerRush\burger-rush\assets\textures"
if (-not (Test-Path $texDir)) { New-Item -ItemType Directory -Force -Path $texDir | Out-Null }

# 1. Warm Wood Planks (512x512)
$bmp = New-Object System.Drawing.Bitmap(512, 512)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(255, 115, 75, 45))
$plankH = 64
$plankColors = @(
    [System.Drawing.Color]::FromArgb(255, 135, 88, 52),
    [System.Drawing.Color]::FromArgb(255, 112, 70, 42),
    [System.Drawing.Color]::FromArgb(255, 142, 95, 58),
    [System.Drawing.Color]::FromArgb(255, 122, 78, 48),
    [System.Drawing.Color]::FromArgb(255, 138, 90, 54),
    [System.Drawing.Color]::FromArgb(255, 116, 74, 44),
    [System.Drawing.Color]::FromArgb(255, 132, 86, 52),
    [System.Drawing.Color]::FromArgb(255, 124, 80, 50)
)
$penSeam = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 55, 32, 18), 3)
$penGrain = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(40, 255, 255, 255), 1)
$penGrainDk = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(35, 0, 0, 0), 1)

for ($i = 0; $i -lt 8; $i++) {
    $y = $i * $plankH
    $brush = New-Object System.Drawing.SolidBrush($plankColors[$i % $plankColors.Length])
    $g.FillRectangle($brush, 0, $y, 512, $plankH)
    $brush.Dispose()
    for ($gIdx = 0; $gIdx -lt 5; $gIdx++) {
        $gy = $y + 10 + $gIdx * 10
        $g.DrawLine($penGrain, 0, $gy, 512, $gy)
        $g.DrawLine($penGrainDk, 0, $gy + 3, 512, $gy + 3)
    }
    $g.DrawLine($penSeam, 0, $y, 512, $y)
    $offset = ($i % 2) * 256 + 128
    $g.DrawLine($penSeam, $offset, $y, $offset, $y + $plankH)
    if ($offset -gt 256) {
        $g.DrawLine($penSeam, $offset - 256, $y, $offset - 256, $y + $plankH)
    }
}
$g.DrawLine($penSeam, 0, 511, 512, 511)
$penSeam.Dispose(); $penGrain.Dispose(); $penGrainDk.Dispose(); $g.Dispose()
$bmp.Save("$texDir\wood_planks_warm.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# 2. White Subway Tiles (512x512)
$bmp = New-Object System.Drawing.Bitmap(512, 512)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(255, 45, 48, 52))
$tileW = 128; $tileH = 64
$brushTile = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 246, 245, 240))
$brushBevel = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 228, 226, 220))
for ($row = 0; $row -lt 9; $row++) {
    $y = $row * $tileH
    $shift = ($row % 2) * ($tileW / 2)
    for ($col = -1; $col -lt 5; $col++) {
        $x = $col * $tileW + $shift
        $g.FillRectangle($brushBevel, $x + 2, $y + 2, $tileW - 4, $tileH - 4)
        $g.FillRectangle($brushTile, $x + 5, $y + 5, $tileW - 10, $tileH - 10)
    }
}
$brushTile.Dispose(); $brushBevel.Dispose(); $g.Dispose()
$bmp.Save("$texDir\subway_tiles_white.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# 3. Dark Slate Kitchen Tiles (512x512)
$bmp = New-Object System.Drawing.Bitmap(512, 512)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(255, 28, 30, 34))
$tSize = 128
$c1 = [System.Drawing.Color]::FromArgb(255, 52, 56, 62)
$c2 = [System.Drawing.Color]::FromArgb(255, 44, 47, 52)
for ($r = 0; $r -lt 4; $r++) {
    for ($c = 0; $c -lt 4; $c++) {
        $x = $c * $tSize; $y = $r * $tSize
        $useCol = if (($r + $c) % 2 -eq 0) { $c1 } else { $c2 }
        $br = New-Object System.Drawing.SolidBrush($useCol)
        $g.FillRectangle($br, $x + 3, $y + 3, $tSize - 6, $tSize - 6)
        $br.Dispose()
    }
}
$g.Dispose()
$bmp.Save("$texDir\slate_tiles_dark.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# 4. Sidewalk Concrete (512x512)
$bmp = New-Object System.Drawing.Bitmap(512, 512)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(255, 160, 164, 168))
$penGrout = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 100, 104, 108), 4)
for ($i = 0; $i -lt 4; $i++) {
    $pos = $i * 128
    $g.DrawLine($penGrout, $pos, 0, $pos, 512)
    $g.DrawLine($penGrout, 0, $pos, 512, $pos)
}
$penGrout.Dispose(); $g.Dispose()
$bmp.Save("$texDir\sidewalk_concrete.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# 5. Asphalt Road (512x512)
$bmp = New-Object System.Drawing.Bitmap(512, 512)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(255, 40, 42, 45))
$penDash = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 230, 230, 230), 16)
$penDash.DashPattern = @(4.0, 3.0)
$g.DrawLine($penDash, 256, 0, 256, 512)
$penDash.Dispose(); $g.Dispose()
$bmp.Save("$texDir\asphalt_road.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# 6. Brick Facade (512x512)
$bmp = New-Object System.Drawing.Bitmap(512, 512)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(255, 55, 50, 46))
$bW = 128; $bH = 42
$bCols = @(
    [System.Drawing.Color]::FromArgb(255, 140, 60, 48),
    [System.Drawing.Color]::FromArgb(255, 125, 52, 42),
    [System.Drawing.Color]::FromArgb(255, 155, 68, 54),
    [System.Drawing.Color]::FromArgb(255, 118, 48, 38)
)
for ($row = 0; $row -lt 14; $row++) {
    $y = $row * $bH
    $shift = ($row % 2) * ($bW / 2)
    for ($col = -1; $col -lt 6; $col++) {
        $x = $col * $bW + $shift
        $brCol = $bCols[($row * 3 + $col) % $bCols.Length]
        $br = New-Object System.Drawing.SolidBrush($brCol)
        $g.FillRectangle($br, $x + 3, $y + 3, $bW - 6, $bH - 6)
        $br.Dispose()
    }
}
$g.Dispose()
$bmp.Save("$texDir\brick_facade.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# 7. Cardboard Kraft (512x512)
$bmp = New-Object System.Drawing.Bitmap(512, 512)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(255, 192, 146, 96))
$penFiber = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(30, 0, 0, 0), 2)
for ($y = 0; $y -lt 512; $y += 12) {
    $g.DrawLine($penFiber, 0, $y, 512, $y)
}
$font = New-Object System.Drawing.Font("Arial", 28, [System.Drawing.FontStyle]::Bold)
$brushLogo = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(160, 160, 20, 20))
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = [System.Drawing.StringAlignment]::Center
$g.DrawString("BURGER RUSH", $font, $brushLogo, 256, 210, $sf)
$fontSm = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
$g.DrawString("FRESH FAST FOOD - 100% ARTISANAL", $fontSm, $brushLogo, 256, 260, $sf)
$penFiber.Dispose(); $font.Dispose(); $fontSm.Dispose(); $brushLogo.Dispose(); $sf.Dispose(); $g.Dispose()
$bmp.Save("$texDir\cardboard_kraft.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# 8. Chalkboard Menu Board (1024x512)
$bmp = New-Object System.Drawing.Bitmap(1024, 512)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(255, 24, 28, 30))
$penBorder = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 160, 110, 60), 16)
$g.DrawRectangle($penBorder, 8, 8, 1008, 496)
$penChalkLine = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 240, 240, 220), 3)
$g.DrawRectangle($penChalkLine, 24, 24, 976, 464)

$fontTitle = New-Object System.Drawing.Font("Arial", 36, [System.Drawing.FontStyle]::Bold)
$fontItem = New-Object System.Drawing.Font("Arial", 26, [System.Drawing.FontStyle]::Bold)
$fontPrice = New-Object System.Drawing.Font("Arial", 26, [System.Drawing.FontStyle]::Bold)
$brushTitle = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 210, 60))
$brushItem = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 245, 245, 240))
$brushPrice = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 110, 230, 110))
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = [System.Drawing.StringAlignment]::Center

$g.DrawString("BURGER RUSH MENU", $fontTitle, $brushTitle, 512, 45, $sf)
$g.DrawLine($penChalkLine, 120, 105, 904, 105)

$items = @(
    @("CHEESEBURGER", "`$18.00", "Pao brioche, carne grelhada, queijo cheddar"),
    @("X-BACON ARTISANAL", "`$25.00", "Pao brioche, carne dupla, cheddar, bacon crocante"),
    @("BATATA FRITA CROCANTE", "`$8.00", "Porcao de batatas douradas e salgadas"),
    @("REFRIGERANTE GELADO (500ml)", "`$6.00", "Cola, Guarana da Amazonia ou Limao")
)
for ($i = 0; $i -lt $items.Length; $i++) {
    $y = 135 + $i * 80
    $g.DrawString($items[$i][0], $fontItem, $brushItem, 60, $y)
    $g.DrawString($items[$i][1], $fontPrice, $brushPrice, 850, $y)
    $fontDesc = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Italic)
    $brushDesc = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 200, 200, 190))
    $g.DrawString($items[$i][2], $fontDesc, $brushDesc, 60, $y + 36)
    $fontDesc.Dispose(); $brushDesc.Dispose()
}
$penBorder.Dispose(); $penChalkLine.Dispose(); $fontTitle.Dispose(); $fontItem.Dispose(); $fontPrice.Dispose(); $brushTitle.Dispose(); $brushItem.Dispose(); $brushPrice.Dispose(); $sf.Dispose(); $g.Dispose()
$bmp.Save("$texDir\chalkboard_menu.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# 9. Retro Diner Poster 1 (512x768)
$bmp = New-Object System.Drawing.Bitmap(512, 768)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(255, 235, 222, 195))
$penPostFrame = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 175, 25, 25), 14)
$g.DrawRectangle($penPostFrame, 14, 14, 484, 740)
$brushHdr = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 175, 25, 25))
$g.FillRectangle($brushHdr, 24, 24, 464, 120)

$fontHdr = New-Object System.Drawing.Font("Arial", 36, [System.Drawing.FontStyle]::Bold)
$brushWht = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 245, 225))
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = [System.Drawing.StringAlignment]::Center
$g.DrawString("BURGER RUSH", $fontHdr, $brushWht, 256, 40, $sf)
$fontSub = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
$g.DrawString("FRESH AND TASTY EVERY DAY", $fontSub, $brushWht, 256, 95, $sf)

$brushBun = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 215, 135, 55))
$brushMeat = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 95, 45, 25))
$brushChd = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 185, 30))
$brushLet = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 60, 170, 50))
$g.FillPie($brushBun, 106, 240, 300, 180, 180, 180)
$g.FillRectangle($brushChd, 96, 330, 320, 30)
$g.FillRectangle($brushMeat, 116, 360, 280, 50)
$g.FillRectangle($brushLet, 106, 410, 300, 30)
$g.FillRectangle($brushBun, 116, 440, 280, 45)

$fontCall = New-Object System.Drawing.Font("Arial", 30, [System.Drawing.FontStyle]::Bold)
$brushDk = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 40, 40, 40))
$g.DrawString("100% ARTISANAL BEEF", $fontCall, $brushDk, 256, 540, $sf)
$fontFooter = New-Object System.Drawing.Font("Arial", 18, [System.Drawing.FontStyle]::Italic)
$g.DrawString("Grilled to perfection with secret recipe!", $fontFooter, $brushDk, 256, 610, $sf)

$penPostFrame.Dispose(); $brushHdr.Dispose(); $fontHdr.Dispose(); $brushWht.Dispose(); $fontSub.Dispose(); $brushBun.Dispose(); $brushMeat.Dispose(); $brushChd.Dispose(); $brushLet.Dispose(); $fontCall.Dispose(); $brushDk.Dispose(); $fontFooter.Dispose(); $sf.Dispose(); $g.Dispose()
$bmp.Save("$texDir\diner_poster_burger.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# 10. Retro Diner Poster 2 (512x768)
$bmp = New-Object System.Drawing.Bitmap(512, 768)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(255, 220, 240, 235))
$penPostFrame = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 30, 115, 80), 14)
$g.DrawRectangle($penPostFrame, 14, 14, 484, 740)
$brushHdr = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 30, 115, 80))
$g.FillRectangle($brushHdr, 24, 24, 464, 120)

$fontHdr = New-Object System.Drawing.Font("Arial", 36, [System.Drawing.FontStyle]::Bold)
$brushWht = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = [System.Drawing.StringAlignment]::Center
$g.DrawString("ICE COLD SODA", $fontHdr, $brushWht, 256, 40, $sf)
$fontSub = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
$g.DrawString("AND GOLDEN CRISPY FRIES", $fontSub, $brushWht, 256, 95, $sf)

$brushCup = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 210, 40, 40))
$brushFryBox = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 230, 60, 40))
$brushFryStick = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 200, 40))
$g.FillRectangle($brushCup, 130, 280, 110, 180)
$g.FillRectangle($brushFryBox, 270, 320, 120, 140)
for ($f = 0; $f -lt 6; $f++) {
    $g.FillRectangle($brushFryStick, 280 + $f * 18, 250 + ($f % 3) * 15, 14, 100)
}

$fontCall = New-Object System.Drawing.Font("Arial", 30, [System.Drawing.FontStyle]::Bold)
$brushDk = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 30, 50, 40))
$g.DrawString("THE PERFECT COMBO", $fontCall, $brushDk, 256, 540, $sf)
$fontFooter = New-Object System.Drawing.Font("Arial", 18, [System.Drawing.FontStyle]::Italic)
$g.DrawString("Always crispy, fresh and ice cold!", $fontFooter, $brushDk, 256, 610, $sf)

$penPostFrame.Dispose(); $brushHdr.Dispose(); $fontHdr.Dispose(); $brushWht.Dispose(); $fontSub.Dispose(); $brushCup.Dispose(); $brushFryBox.Dispose(); $brushFryStick.Dispose(); $fontCall.Dispose(); $brushDk.Dispose(); $fontFooter.Dispose(); $sf.Dispose(); $g.Dispose()
$bmp.Save("$texDir\diner_poster_shake.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# 11. Soda Machine Header & 3 Flavor Badges (1024x512)
$bmp = New-Object System.Drawing.Bitmap(1024, 512)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(255, 20, 22, 26))

$brushHdr = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 185, 25, 25))
$g.FillRectangle($brushHdr, 20, 20, 984, 150)
$fontMain = New-Object System.Drawing.Font("Arial", 46, [System.Drawing.FontStyle]::Bold)
$fontSubHdr = New-Object System.Drawing.Font("Arial", 22, [System.Drawing.FontStyle]::Bold)
$brushWht = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = [System.Drawing.StringAlignment]::Center
$g.DrawString("BURGER RUSH SODA BAR", $fontMain, $brushWht, 512, 45, $sf)
$brushGold = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 215, 60))
$g.DrawString("ICE COLD BEVERAGES - PUSH LEVER TO DISPENSE", $fontSubHdr, $brushGold, 512, 115, $sf)

# 3 Flavor Badges
# Flavor 1: COLA
$brushCola = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 160, 20, 20))
$g.FillRectangle($brushCola, 50, 200, 280, 280)
$penBadge = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 255, 255), 6)
$g.DrawRectangle($penBadge, 55, 205, 270, 270)
$fontFlav = New-Object System.Drawing.Font("Arial", 36, [System.Drawing.FontStyle]::Bold)
$g.DrawString("COLA", $fontFlav, $brushWht, 190, 270, $sf)
$fontSubF = New-Object System.Drawing.Font("Arial", 20, [System.Drawing.FontStyle]::Bold)
$g.DrawString("CLASSIC TASTE", $fontSubF, $brushGold, 190, 340, $sf)

# Flavor 2: GUARANA
$brushGuarana = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 25, 130, 45))
$g.FillRectangle($brushGuarana, 372, 200, 280, 280)
$g.DrawRectangle($penBadge, 377, 205, 270, 270)
$g.DrawString("GUARANA", $fontFlav, $brushWht, 512, 270, $sf)
$g.DrawString("AMAZON GOLD", $fontSubF, $brushGold, 512, 340, $sf)

# Flavor 3: LIMAO / CITRUS
$brushLemon = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 190, 175, 20))
$g.FillRectangle($brushLemon, 694, 200, 280, 280)
$g.DrawRectangle($penBadge, 699, 205, 270, 270)
$g.DrawString("LIMAO", $fontFlav, $brushWht, 834, 270, $sf)
$g.DrawString("CITRUS FRESH", $fontSubF, $brushWht, 834, 340, $sf)

$brushHdr.Dispose(); $fontMain.Dispose(); $fontSubHdr.Dispose(); $brushWht.Dispose(); $brushGold.Dispose(); $brushCola.Dispose(); $penBadge.Dispose(); $fontFlav.Dispose(); $fontSubF.Dispose(); $brushGuarana.Dispose(); $brushLemon.Dispose(); $sf.Dispose(); $g.Dispose()
$bmp.Save("$texDir\soda_machine_panel.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# 12. Character Face - Customer (256x256)
$bmp = New-Object System.Drawing.Bitmap(256, 256)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(255, 235, 198, 165))
$brushEye = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 35, 38, 45))
$brushWht = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
$penSmile = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 60, 40, 35), 4)
$penEyebrow = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 75, 45, 30), 5)

$g.FillEllipse($brushEye, 55, 95, 35, 45)
$g.FillEllipse($brushWht, 62, 102, 12, 15)
$g.FillEllipse($brushEye, 166, 95, 35, 45)
$g.FillEllipse($brushWht, 173, 102, 12, 15)
$g.DrawArc($penEyebrow, 48, 70, 50, 25, 190, 160)
$g.DrawArc($penEyebrow, 158, 70, 50, 25, 190, 160)
$g.DrawArc($penSmile, 90, 155, 76, 45, 20, 140)

$brushEye.Dispose(); $brushWht.Dispose(); $penSmile.Dispose(); $penEyebrow.Dispose(); $g.Dispose()
$bmp.Save("$texDir\character_face_customer.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# 13. Character Face - Employee (256x256)
$bmp = New-Object System.Drawing.Bitmap(256, 256)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(255, 235, 198, 165))
$brushEye = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 30, 30, 35))
$brushWht = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
$penSmile = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 60, 40, 35), 5)
$penEyebrow = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 75, 45, 30), 5)

$g.FillEllipse($brushEye, 55, 95, 35, 45)
$g.FillEllipse($brushWht, 62, 102, 12, 15)
$g.FillEllipse($brushEye, 166, 95, 35, 45)
$g.FillEllipse($brushWht, 173, 102, 12, 15)
$g.DrawArc($penEyebrow, 50, 72, 48, 20, 190, 160)
$g.DrawArc($penEyebrow, 158, 72, 48, 20, 190, 160)
$g.DrawArc($penSmile, 85, 150, 86, 50, 15, 150)

$brushEye.Dispose(); $brushWht.Dispose(); $penSmile.Dispose(); $penEyebrow.Dispose(); $g.Dispose()
$bmp.Save("$texDir\character_face_employee.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# 14. Burger Box Top (512x512)
$bmp = New-Object System.Drawing.Bitmap(512, 512)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(255, 190, 142, 92))
$penSeal = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 175, 25, 25), 8)
$g.DrawEllipse($penSeal, 106, 106, 300, 300)
$fontB = New-Object System.Drawing.Font("Arial", 32, [System.Drawing.FontStyle]::Bold)
$fontSm = New-Object System.Drawing.Font("Arial", 18, [System.Drawing.FontStyle]::Bold)
$brushRed = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 175, 25, 25))
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = [System.Drawing.StringAlignment]::Center
$g.DrawString("BURGER", $fontB, $brushRed, 256, 180, $sf)
$g.DrawString("RUSH", $fontB, $brushRed, 256, 230, $sf)
$g.DrawString("100% ARTISANAL", $fontSm, $brushRed, 256, 310, $sf)

$penSeal.Dispose(); $fontB.Dispose(); $fontSm.Dispose(); $brushRed.Dispose(); $sf.Dispose(); $g.Dispose()
$bmp.Save("$texDir\burger_box_top.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# 15. Fries Box Graphic (512x512)
$bmp = New-Object System.Drawing.Bitmap(512, 512)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(255, 215, 35, 30))
$brushGold = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 205, 45))
$g.FillRectangle($brushGold, 0, 420, 512, 40)
$fontBR = New-Object System.Drawing.Font("Arial", 72, [System.Drawing.FontStyle]::Bold)
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = [System.Drawing.StringAlignment]::Center
$g.DrawString("BR", $fontBR, $brushGold, 256, 170, $sf)
$fontFries = New-Object System.Drawing.Font("Arial", 22, [System.Drawing.FontStyle]::Bold)
$brushWht = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
$g.DrawString("BURGER RUSH FRIES", $fontFries, $brushWht, 256, 310, $sf)

$brushGold.Dispose(); $fontBR.Dispose(); $fontFries.Dispose(); $brushWht.Dispose(); $sf.Dispose(); $g.Dispose()
$bmp.Save("$texDir\fries_box_graphic.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# 16. Drink Cup Wrap (512x512)
$bmp = New-Object System.Drawing.Bitmap(512, 512)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(255, 215, 35, 30))
$brushWht = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
$g.FillRectangle($brushWht, 0, 160, 512, 190)
$fontBR = New-Object System.Drawing.Font("Arial", 36, [System.Drawing.FontStyle]::Bold)
$brushRed = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 215, 35, 30))
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = [System.Drawing.StringAlignment]::Center
$g.DrawString("BURGER RUSH", $fontBR, $brushRed, 256, 200, $sf)
$fontSub = New-Object System.Drawing.Font("Arial", 20, [System.Drawing.FontStyle]::Bold)
$brushGold = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 215, 140, 20))
$g.DrawString("ICE COLD SODA BAR", $fontSub, $brushGold, 256, 270, $sf)

$brushWht.Dispose(); $fontBR.Dispose(); $brushRed.Dispose(); $fontSub.Dispose(); $brushGold.Dispose(); $sf.Dispose(); $g.Dispose()
$bmp.Save("$texDir\drink_cup_wrap.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

Write-Output "ALL 16 TEXTURES GENERATED SUCCESSFULLY!"
