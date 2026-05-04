#Requires -Version 5.1
<#
.SYNOPSIS
    Gera app_icon.ico para o ClipFlow Downloader usando GDI+ puro (sem dependencias externas).
    Fundo verde/teal escuro com seta de download branca, legivel em 16x16, 32x32, 48x48 e 256x256.

.EXAMPLE
    .\scripts\generate_windows_icon.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$OutputPath = Join-Path (Split-Path $PSScriptRoot -Parent) "windows\runner\resources\app_icon.ico"

# Tamanhos padrao ICO
$sizes = @(16, 32, 48, 256)

# Cores: fundo teal escuro, simbolo branco
$bgColor  = [System.Drawing.Color]::FromArgb(255, 26, 95, 90)   # #1A5F5A
$fgColor  = [System.Drawing.Color]::White

function New-IconBitmap([int]$size) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode   = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    # Fundo com cantos arredondados
    $radius = [int]($size * 0.18)
    $brush  = New-Object System.Drawing.SolidBrush($bgColor)
    $path   = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc(0, 0, $radius*2, $radius*2, 180, 90)
    $path.AddArc($size - $radius*2, 0, $radius*2, $radius*2, 270, 90)
    $path.AddArc($size - $radius*2, $size - $radius*2, $radius*2, $radius*2, 0, 90)
    $path.AddArc(0, $size - $radius*2, $radius*2, $radius*2, 90, 90)
    $path.CloseFigure()
    $g.FillPath($brush, $path)

    # Seta de download: corpo (retangulo vertical) + ponta triangular
    $fgBrush = New-Object System.Drawing.SolidBrush($fgColor)
    $pad     = [int]($size * 0.20)
    $lineW   = [int]([Math]::Max(2, $size * 0.12))
    $arrowH  = [int]($size * 0.28)
    $shaftH  = [int]($size * 0.28)
    $cx      = $size / 2

    # Haste vertical (shaft) - centrada, acima da ponta
    $shaftX = $cx - $lineW / 2
    $shaftY = $pad
    $g.FillRectangle($fgBrush, $shaftX, $shaftY, $lineW, $shaftH)

    # Ponta da seta (triangulo apontando para baixo)
    $tipY   = $shaftY + $shaftH
    $halfW  = [int]($size * 0.22)
    $arrow  = [System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new($cx - $halfW, $tipY),
        [System.Drawing.PointF]::new($cx + $halfW, $tipY),
        [System.Drawing.PointF]::new($cx,           $tipY + $arrowH)
    )
    $g.FillPolygon($fgBrush, $arrow)

    # Linha horizontal na base (plataforma de download)
    $lineH2 = [int]([Math]::Max(2, $size * 0.10))
    $lineY  = [int]($size * 0.75)
    $g.FillRectangle($fgBrush, $pad, $lineY, $size - $pad*2, $lineH2)

    $g.Dispose()
    $brush.Dispose()
    $fgBrush.Dispose()
    $path.Dispose()
    return $bmp
}

# Gera bitmaps para cada tamanho
$bitmaps = @{}
foreach ($sz in $sizes) {
    $bitmaps[$sz] = New-IconBitmap $sz
}

# Escreve arquivo ICO manualmente (formato ICO nao e suportado nativamente pelo GDI+)
# Formato: ICONDIR + ICONDIRENTRYs + dados PNG/BMP de cada imagem
# Para tamanhos >= 256 usamos PNG, para menores usamos BMP 32bpp.

$stream = New-Object System.IO.MemoryStream

function Write-UInt16([System.IO.Stream]$s, [int]$v) {
    $s.WriteByte($v -band 0xFF)
    $s.WriteByte(($v -shr 8) -band 0xFF)
}
function Write-UInt32([System.IO.Stream]$s, [int]$v) {
    $s.WriteByte($v -band 0xFF)
    $s.WriteByte(($v -shr 8) -band 0xFF)
    $s.WriteByte(($v -shr 16) -band 0xFF)
    $s.WriteByte(($v -shr 24) -band 0xFF)
}

# Serializa cada imagem para bytes
$imageDataList = [System.Collections.Generic.List[byte[]]]::new()
foreach ($sz in $sizes) {
    $bmp = $bitmaps[$sz]
    $ms  = New-Object System.IO.MemoryStream
    if ($sz -ge 256) {
        # PNG embutido (Windows Vista+)
        $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    } else {
        # BMP sem cabecalho BITMAPFILEHEADER, com mascara AND
        $bmpMs = New-Object System.IO.MemoryStream
        # BITMAPINFOHEADER (40 bytes)
        $w  = $sz
        $h  = $sz
        $bmpMs.Write([BitConverter]::GetBytes([int32]40), 0, 4)         # biSize
        $bmpMs.Write([BitConverter]::GetBytes([int32]$w), 0, 4)         # biWidth
        $bmpMs.Write([BitConverter]::GetBytes([int32]($h*2)), 0, 4)     # biHeight (dobrado: XOR + AND)
        $bmpMs.Write([BitConverter]::GetBytes([int16]1), 0, 2)          # biPlanes
        $bmpMs.Write([BitConverter]::GetBytes([int16]32), 0, 2)         # biBitCount
        $bmpMs.Write([BitConverter]::GetBytes([int32]0), 0, 4)          # biCompression BI_RGB
        $bmpMs.Write([BitConverter]::GetBytes([int32]0), 0, 4)          # biSizeImage
        $bmpMs.Write([BitConverter]::GetBytes([int32]0), 0, 4)          # biXPelsPerMeter
        $bmpMs.Write([BitConverter]::GetBytes([int32]0), 0, 4)          # biYPelsPerMeter
        $bmpMs.Write([BitConverter]::GetBytes([int32]0), 0, 4)          # biClrUsed
        $bmpMs.Write([BitConverter]::GetBytes([int32]0), 0, 4)          # biClrImportant
        # Pixels XOR (BGRA, bottom-up)
        for ($y = $h-1; $y -ge 0; $y--) {
            for ($x = 0; $x -lt $w; $x++) {
                $px = $bmp.GetPixel($x, $y)
                $bmpMs.WriteByte($px.B)
                $bmpMs.WriteByte($px.G)
                $bmpMs.WriteByte($px.R)
                $bmpMs.WriteByte($px.A)
            }
        }
        # Mascara AND: 0 = opaco (todos os pixels opacos)
        $andRowBytes = [int]([Math]::Ceiling($w / 8.0))
        # AND mask row must be DWORD-aligned
        $andRowPadded = [int]([Math]::Ceiling($andRowBytes / 4.0)) * 4
        $andRow = New-Object byte[] $andRowPadded
        for ($y = 0; $y -lt $h; $y++) {
            $bmpMs.Write($andRow, 0, $andRowPadded)
        }
        $ms.Write($bmpMs.ToArray(), 0, $bmpMs.Length)
        $bmpMs.Dispose()
    }
    $imageDataList.Add($ms.ToArray())
    $ms.Dispose()
}

# Cabecalho ICONDIR: Reserved(2) + Type(2) + Count(2)
$count = $sizes.Count
Write-UInt16 $stream 0       # Reserved
Write-UInt16 $stream 1       # Type = ICO
Write-UInt16 $stream $count  # Count

# Calcular offsets: cabecalho(6) + entries(count*16) + dados acumulados
$headerSize = 6 + $count * 16
$offset = $headerSize

# Escrever ICONDIRENTRY para cada imagem
for ($i = 0; $i -lt $count; $i++) {
    $sz   = $sizes[$i]
    $data = $imageDataList[$i]
    $w8   = if ($sz -eq 256) { 0 } else { $sz }
    $h8   = if ($sz -eq 256) { 0 } else { $sz }
    $stream.WriteByte($w8)           # Width
    $stream.WriteByte($h8)           # Height
    $stream.WriteByte(0)             # ColorCount (0 = true color)
    $stream.WriteByte(0)             # Reserved
    Write-UInt16 $stream 1           # Planes
    Write-UInt16 $stream 32          # BitCount
    Write-UInt32 $stream $data.Length  # BytesInRes
    Write-UInt32 $stream $offset       # ImageOffset
    $offset += $data.Length
}

# Escrever dados de cada imagem
foreach ($data in $imageDataList) {
    $stream.Write($data, 0, $data.Length)
}

# Salvar arquivo
[System.IO.File]::WriteAllBytes($OutputPath, $stream.ToArray())
$stream.Dispose()

# Limpar bitmaps
foreach ($sz in $sizes) { $bitmaps[$sz].Dispose() }

Write-Host "[OK] Icone gerado: $OutputPath" -ForegroundColor Green
Write-Host "     Tamanhos: $($sizes -join ', ')px"
