Add-Type -AssemblyName System.Drawing

# 1. Base Brown Kraft Cardboard Box Texture (512x512)
$bmp = New-Object System.Drawing.Bitmap(512, 512)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

# Kraft paper brown background
$cardboardColor = [System.Drawing.Color]::FromArgb(255, 196, 150, 98)
$g.Clear($cardboardColor)

# Paper grain / corrugation noise lines
$noisePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(25, 120, 80, 40), 1)
$rand = New-Object System.Random(42)
for ($y = 0; $y -lt 512; $y += 3) {
    $alpha = $rand.Next(15, 35)
    $noisePen.Color = [System.Drawing.Color]::FromArgb($alpha, 140, 95, 50)
    $g.DrawLine($noisePen, 0, $y, 512, $y)
}

# Dark edge seams (Flaps border)
$edgePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(100, 110, 75, 40), 3)
$g.DrawRectangle($edgePen, 2, 2, 508, 508)

# Center packaging tape (Brown packing tape with slight shine)
$tapeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 165, 115, 65))
$g.FillRectangle($tapeBrush, 0, 220, 512, 72)
$tapeEdgePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(120, 120, 80, 40), 2)
$g.DrawLine($tapeEdgePen, 0, 220, 512, 220)
$g.DrawLine($tapeEdgePen, 0, 292, 512, 292)

# Black ink industrial stamps: "FRAGILE / THIS SIDE UP" & "BURGER RUSH SUPPLY CO."
$inkBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(190, 45, 35, 25))
$fontStamp = New-Object System.Drawing.Font("Arial Black", 12, [System.Drawing.FontStyle]::Bold)
$fontSmall = New-Object System.Drawing.Font("Impact", 16, [System.Drawing.FontStyle]::Regular)

$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = [System.Drawing.StringAlignment]::Near
$sf.LineAlignment = [System.Drawing.StringAlignment]::Center

$g.DrawString("BURGER RUSH LOGISTICS", $fontSmall, $inkBrush, 24, 40, $sf)
$g.DrawString("HANDLE WITH CARE  |  KEEP DRY", $fontStamp, $inkBrush, 24, 75, $sf)

# Draw "THIS SIDE UP" arrows on bottom-right
$arrowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 40, 30, 20))
$g.FillRectangle($arrowBrush, 430, 400, 12, 45)
$g.FillPolygon($arrowBrush, @(
    (New-Object System.Drawing.Point(436, 380)),
    (New-Object System.Drawing.Point(420, 405)),
    (New-Object System.Drawing.Point(452, 405))
))

$g.FillRectangle($arrowBrush, 465, 400, 12, 45)
$g.FillPolygon($arrowBrush, @(
    (New-Object System.Drawing.Point(471, 380)),
    (New-Object System.Drawing.Point(455, 405)),
    (New-Object System.Drawing.Point(487, 405))
))

$destPath = "c:\BurgerRush\burger-rush\assets\textures\cardboard_box_kraft.png"
$bmp.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
$g.Dispose()

Write-Host "Cardboard texture created successfully!"
