#Requires -Version 5.1
<#
.SYNOPSIS
    Gera pacote portavel Windows do ClipFlow Downloader.

.PARAMETER Version
    Versao do pacote. Default: "dev"

.PARAMETER OutputRoot
    Pasta raiz de saida. Default: "dist"

.PARAMETER SkipTests
    Se informado, pula dart analyze e flutter test.

.EXAMPLE
    .\scripts\build_windows_portable.ps1 -Version "1.0.0"
    .\scripts\build_windows_portable.ps1 -Version "preview" -SkipTests
#>
param(
    [string]$Version    = "dev",
    [string]$OutputRoot = "dist",
    [switch]$SkipTests
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step([string]$msg) {
    Write-Host ""
    Write-Host ">>> $msg" -ForegroundColor Cyan
}
function Write-Ok([string]$msg)   { Write-Host "    [OK] $msg"     -ForegroundColor Green  }
function Write-Warn([string]$msg) { Write-Host "    [AVISO] $msg"  -ForegroundColor Yellow }
function Write-Fail([string]$msg) { Write-Host "    [ERRO] $msg"   -ForegroundColor Red    }

# Padroes bloqueados por seguranca
$BlockedPatterns = @('*cookie*','*cookies*','*profile*','*firefox*','*browser-profile*','*firefox-profile*')

function Test-IsBlocked([string]$name) {
    $lower = $name.ToLowerInvariant()
    foreach ($pat in $BlockedPatterns) {
        if ($lower -like $pat) { return $true }
    }
    return $false
}

# Raiz do projeto = pai da pasta scripts
$ProjectRoot = Split-Path $PSScriptRoot -Parent
if (-not (Test-Path (Join-Path $ProjectRoot "pubspec.yaml"))) {
    Write-Fail "pubspec.yaml nao encontrado em: $ProjectRoot"
    exit 1
}

Push-Location $ProjectRoot

# ---------------------------------------------------------------------------
# 1. Testes
# ---------------------------------------------------------------------------
if (-not $SkipTests) {
    Write-Step "Analisando codigo (dart analyze)..."
    dart analyze
    if ($LASTEXITCODE -ne 0) { Pop-Location; Write-Fail "dart analyze falhou."; exit 1 }
    Write-Ok "dart analyze OK"

    Write-Step "Rodando widget_test..."
    flutter test test/widget_test.dart --reporter expanded
    if ($LASTEXITCODE -ne 0) { Pop-Location; Write-Fail "widget_test falhou."; exit 1 }
    Write-Ok "widget_test OK"

    Write-Step "Rodando encoding_guard_test..."
    flutter test test/encoding_guard_test.dart --reporter expanded
    if ($LASTEXITCODE -ne 0) { Pop-Location; Write-Fail "encoding_guard_test falhou."; exit 1 }
    Write-Ok "encoding_guard_test OK"
} else {
    Write-Warn "Testes ignorados (SkipTests ativado)."
}

# ---------------------------------------------------------------------------
# 2. Build release
# ---------------------------------------------------------------------------
Write-Step "Executando flutter build windows --release..."
flutter build windows --release
if ($LASTEXITCODE -ne 0) { Pop-Location; Write-Fail "flutter build windows --release falhou."; exit 1 }
Write-Ok "Build concluido."

# ---------------------------------------------------------------------------
# 3. Localizar pasta Release
# ---------------------------------------------------------------------------
$ReleaseDir = Join-Path $ProjectRoot "build\windows\x64\runner\Release"
if (-not (Test-Path $ReleaseDir)) {
    Pop-Location
    Write-Fail "Pasta Release nao encontrada: $ReleaseDir"
    exit 1
}
Write-Ok "Release encontrada em: $ReleaseDir"

# ---------------------------------------------------------------------------
# 4. Criar pasta de destino
# ---------------------------------------------------------------------------
$PackageName = "ClipFlow-Downloader-portable-$Version"
$PackageDir  = Join-Path (Join-Path $ProjectRoot $OutputRoot) $PackageName

if (Test-Path $PackageDir) {
    Write-Warn "Pasta de destino ja existe -- sera sobrescrita: $PackageDir"
    Remove-Item $PackageDir -Recurse -Force
}
New-Item -ItemType Directory -Path $PackageDir -Force | Out-Null
Write-Ok "Pasta de destino criada: $PackageDir"

# ---------------------------------------------------------------------------
# 5. Copiar conteudo da Release
# ---------------------------------------------------------------------------
Write-Step "Copiando arquivos da Release..."
Copy-Item -Path (Join-Path $ReleaseDir "*") -Destination $PackageDir -Recurse -Force
Write-Ok "Conteudo da Release copiado."

# ---------------------------------------------------------------------------
# 6. Copiar tools (somente binarios permitidos)
# ---------------------------------------------------------------------------
Write-Step "Copiando tools..."

$ToolsSource = Join-Path $ProjectRoot "tools"
$ToolsDest   = Join-Path $PackageDir  "tools"
New-Item -ItemType Directory -Path $ToolsDest -Force | Out-Null

$YtDlpCopied    = $false
$FfmpegCopied   = $false
$FfprobeCopied  = $false
$YtDlpSrc       = $null
$FfmpegSrc      = $null
$FfprobeSrc     = $null

# Funcao: localiza o primeiro caminho valido de uma lista de candidatos.
# Jamais busca dentro de ffmpeg-temp.
function Find-ToolBin([string]$binName, [string[]]$candidates) {
    foreach ($c in $candidates) {
        if (Test-Path $c) {
            # Rejeitar qualquer coisa dentro de ffmpeg-temp
            if ($c -match [regex]::Escape("ffmpeg-temp")) { continue }
            return $c
        }
    }
    # Busca generica dentro de tools/ffmpeg/ (exceto ffmpeg-temp)
    $found = Get-ChildItem $ToolsSource -Filter $binName -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch [regex]::Escape("ffmpeg-temp") } |
        Select-Object -First 1
    if ($found) { return $found.FullName }
    return $null
}

# yt-dlp
$ytDlpCandidates = @(
    (Join-Path $ToolsSource "yt-dlp.exe")
)
$YtDlpSrc = Find-ToolBin "yt-dlp.exe" $ytDlpCandidates
if ($YtDlpSrc) {
    Copy-Item -Path $YtDlpSrc -Destination $ToolsDest -Force
    $YtDlpCopied = $true
    Write-Ok "yt-dlp.exe copiado de: $YtDlpSrc"
} else {
    Write-Warn "yt-dlp.exe nao encontrado."
}

# ffmpeg
$ffmpegCandidates = @(
    (Join-Path $ToolsSource "ffmpeg.exe"),
    (Join-Path $ToolsSource "ffmpeg\ffmpeg.exe"),
    (Join-Path $ToolsSource "ffmpeg\bin\ffmpeg.exe")
)
$FfmpegSrc = Find-ToolBin "ffmpeg.exe" $ffmpegCandidates
if ($FfmpegSrc) {
    Copy-Item -Path $FfmpegSrc -Destination $ToolsDest -Force
    $FfmpegCopied = $true
    Write-Ok "ffmpeg.exe copiado de: $FfmpegSrc"
} else {
    Write-Warn "ffmpeg.exe nao encontrado."
}

# ffprobe
$ffprobeCandidates = @(
    (Join-Path $ToolsSource "ffprobe.exe"),
    (Join-Path $ToolsSource "ffmpeg\ffprobe.exe"),
    (Join-Path $ToolsSource "ffmpeg\bin\ffprobe.exe")
)
$FfprobeSrc = Find-ToolBin "ffprobe.exe" $ffprobeCandidates
if ($FfprobeSrc) {
    Copy-Item -Path $FfprobeSrc -Destination $ToolsDest -Force
    $FfprobeCopied = $true
    Write-Ok "ffprobe.exe copiado de: $FfprobeSrc"
} else {
    Write-Warn "ffprobe.exe nao encontrado."
}

# Remover qualquer arquivo bloqueado que tenha escapado
$copiedFiles = Get-ChildItem $ToolsDest -File -ErrorAction SilentlyContinue
foreach ($f in $copiedFiles) {
    if (Test-IsBlocked $f.Name) {
        Remove-Item $f.FullName -Force
        Write-Warn "Arquivo bloqueado removido do destino: $($f.Name)"
    }
}

# ---------------------------------------------------------------------------
# 7. README_PORTABLE.txt
# ---------------------------------------------------------------------------
Write-Step "Gerando README_PORTABLE.txt..."

$ReadmePath = Join-Path $PackageDir "README_PORTABLE.txt"
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("ClipFlow Downloader - Pacote Portatil Windows")
$lines.Add("=============================================")
$lines.Add("")
$lines.Add("COMO USAR")
$lines.Add("---------")
$lines.Add('1. Extraia esta pasta para qualquer local do seu computador.')
$lines.Add('2. Abra o arquivo "clipflow_downloader.exe" (ou o executavel presente nesta pasta).')
$lines.Add('3. O aplicativo nao precisa de instalacao.')
$lines.Add("")
$lines.Add("YOUTUBE COM PROTECAO ANTI-BOT")
$lines.Add("------------------------------")
$lines.Add("O YouTube pode bloquear downloads diretos. Para contornar isso de forma segura:")
$lines.Add("")
$lines.Add("1. Instale o Firefox (https://www.mozilla.org/) e faca login na sua conta do YouTube.")
$lines.Add("2. Deixe o Firefox aberto enquanto usa o ClipFlow Downloader.")
$lines.Add('3. Nas preferencias do app, ative a opcao "Usar sessao do Firefox para YouTube".')
$lines.Add("")
$lines.Add("O app usara a sua sessao local do Firefox para autenticar os downloads.")
$lines.Add("Nenhum dado de login e transmitido a terceiros.")
$lines.Add("")
$lines.Add("FFMPEG (NECESSARIO PARA QUALIDADE ALTA)")
$lines.Add("----------------------------------------")
$lines.Add("Para baixar videos em qualidade alta (ex: 1080p), o ffmpeg.exe e obrigatorio.")
$lines.Add("Ele e usado para juntar a trilha de video e audio separadas.")
$lines.Add("")
$lines.Add("O ffprobe.exe e recomendado para inspecao de arquivos de midia.")
$lines.Add("")
$lines.Add("Se o pacote nao incluir ffmpeg.exe, coloque manualmente em:")
$lines.Add("    tools\ffmpeg\bin\ffmpeg.exe")
$lines.Add("    tools\ffmpeg\bin\ffprobe.exe")
$lines.Add("")
$lines.Add("Baixe em: https://ffmpeg.org/download.html")
$lines.Add("")
$lines.Add("DENO (RECOMENDADO)")
$lines.Add("------------------")
$lines.Add("Para melhor compatibilidade com o YouTube, instale o Deno:")
$lines.Add("    https://deno.land/")
$lines.Add("")
$lines.Add("Deno e utilizado internamente pelo yt-dlp para alguns extratores avancados.")
$lines.Add("")
$lines.Add("AVISOS IMPORTANTES")
$lines.Add("------------------")
$lines.Add("- Nao compartilhe sua pasta de perfil do Firefox nem arquivos de cookies.")
$lines.Add("- Nao distribua esta pasta contendo dados de sessao pessoais.")
$lines.Add("- Use o ClipFlow Downloader apenas com conteudo que voce tem direito de baixar:")
$lines.Add("  conteudo proprio, conteudo com licenca aberta ou conteudo para uso pessoal")
$lines.Add("  autorizado pelo detentor dos direitos.")
$lines.Add("- O uso indevido para baixar conteudo protegido sem autorizacao e de")
$lines.Add("  responsabilidade exclusiva do usuario.")
$lines.Add("")
$lines.Add("SUPORTE")
$lines.Add("-------")
$lines.Add("Repositorio: https://github.com/brunonaval/clipflow-downloader")

[System.IO.File]::WriteAllText($ReadmePath, ($lines -join "`r`n"), [System.Text.Encoding]::UTF8)
Write-Ok "README_PORTABLE.txt gerado."

# ---------------------------------------------------------------------------
# 8. Criar ZIP
# ---------------------------------------------------------------------------
Write-Step "Compactando pacote em ZIP..."

$ZipPath = Join-Path (Join-Path $ProjectRoot $OutputRoot) "$PackageName.zip"
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($PackageDir, $ZipPath)
Write-Ok "ZIP criado: $ZipPath"

# ---------------------------------------------------------------------------
# 9. Resumo final
# ---------------------------------------------------------------------------
$ExeName = Get-ChildItem $PackageDir -Filter "*.exe" -File |
    Where-Object { $_.Name -notmatch "vc_redist" } |
    Select-Object -First 1 -ExpandProperty Name

Pop-Location

Write-Host ""
Write-Host "============================================================" -ForegroundColor White
Write-Host "  BUILD PORTATIL CONCLUIDO" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor White
Write-Host "  Pasta portavel : $PackageDir"
Write-Host "  ZIP            : $ZipPath"
Write-Host "  Executavel     : $(if ($ExeName) { $ExeName } else { '(nao encontrado)' })"

if ($YtDlpCopied) {
    Write-Host "  yt-dlp.exe     : copiado de $YtDlpSrc" -ForegroundColor Green
} else {
    Write-Host "  yt-dlp.exe     : NAO encontrado" -ForegroundColor Yellow
}

if ($FfmpegCopied) {
    Write-Host "  ffmpeg.exe     : copiado de $FfmpegSrc" -ForegroundColor Green
} else {
    Write-Host "  ffmpeg.exe     : NAO encontrado" -ForegroundColor Red
    Write-Host "  AVISO: ffmpeg.exe nao foi encontrado. Downloads em qualidade alta podem falhar." -ForegroundColor Red
}

if ($FfprobeCopied) {
    Write-Host "  ffprobe.exe    : copiado de $FfprobeSrc" -ForegroundColor Green
} else {
    Write-Host "  ffprobe.exe    : NAO encontrado" -ForegroundColor Yellow
    Write-Host "  AVISO: ffprobe.exe nao foi encontrado. Algumas verificacoes de midia podem falhar." -ForegroundColor Yellow
}

Write-Host "============================================================" -ForegroundColor White
