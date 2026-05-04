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

.PARAMETER RequireFfmpeg
    Se informado, falha o build caso ffmpeg.exe ou ffprobe.exe nao sejam encontrados.

.EXAMPLE
    .\scripts\build_windows_portable.ps1 -Version "1.0.0"
    .\scripts\build_windows_portable.ps1 -Version "preview" -SkipTests
    .\scripts\build_windows_portable.ps1 -Version "0.1.0-preview" -RequireFfmpeg
#>
param(
    [string]$Version    = "dev",
    [string]$OutputRoot = "dist",
    [switch]$SkipTests,
    [switch]$RequireFfmpeg
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step([string]$msg) {
    Write-Host ""
    Write-Host ">>> $msg" -ForegroundColor Cyan
}
function Write-Ok([string]$msg)   { Write-Host "    [OK] $msg"    -ForegroundColor Green  }
function Write-Warn([string]$msg) { Write-Host "    [AVISO] $msg" -ForegroundColor Yellow }
function Write-Fail([string]$msg) { Write-Host "    [ERRO] $msg"  -ForegroundColor Red    }

# Padroes bloqueados por seguranca
$BlockedPatterns = @('*cookie*','*cookies*','*profile*','*firefox*','*browser-profile*','*firefox-profile*')

function Test-IsBlocked([string]$name) {
    $lower = $name.ToLowerInvariant()
    foreach ($pat in $BlockedPatterns) {
        if ($lower -like $pat) { return $true }
    }
    return $false
}

function Get-Sha256([string]$filePath) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $stream = [System.IO.File]::OpenRead($filePath)
    try {
        $hashBytes = $sha.ComputeHash($stream)
        return ([BitConverter]::ToString($hashBytes) -replace '-','').ToUpperInvariant()
    } finally {
        $stream.Dispose()
        $sha.Dispose()
    }
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
$DistRoot    = Join-Path $ProjectRoot $OutputRoot
$PackageDir  = Join-Path $DistRoot $PackageName

if (Test-Path $PackageDir) {
    Write-Warn "Pasta de destino ja existe -- sera sobrescrita: $PackageDir"
    Remove-Item $PackageDir -Recurse -Force
}
New-Item -ItemType Directory -Path $PackageDir -Force | Out-Null
Write-Ok "Pasta de destino criada: $PackageDir"

# ---------------------------------------------------------------------------
# 5. Copiar conteudo da Release e renomear executavel
# ---------------------------------------------------------------------------
Write-Step "Copiando arquivos da Release..."
Copy-Item -Path (Join-Path $ReleaseDir "*") -Destination $PackageDir -Recurse -Force
Write-Ok "Conteudo da Release copiado."

# Renomear executavel para nome final de produto
$OldExePath = Join-Path $PackageDir "clipflow_downloader.exe"
$NewExePath = Join-Path $PackageDir "ClipFlowDownloader.exe"
if (Test-Path $OldExePath) {
    Rename-Item -Path $OldExePath -NewName "ClipFlowDownloader.exe" -Force
    Write-Ok "Executavel renomeado: clipflow_downloader.exe -> ClipFlowDownloader.exe"
} elseif (-not (Test-Path $NewExePath)) {
    Write-Warn "Executavel clipflow_downloader.exe nao encontrado na Release."
}

# ---------------------------------------------------------------------------
# 6. Copiar tools (somente binarios permitidos)
# ---------------------------------------------------------------------------
Write-Step "Copiando tools..."

$ToolsSource = Join-Path $ProjectRoot "tools"
$ToolsDest   = Join-Path $PackageDir  "tools"
New-Item -ItemType Directory -Path $ToolsDest -Force | Out-Null

$YtDlpCopied   = $false
$FfmpegCopied  = $false
$FfprobeCopied = $false
$YtDlpSrc      = $null
$FfmpegSrc     = $null
$FfprobeSrc    = $null

# Localiza o primeiro caminho valido de uma lista de candidatos.
# Nunca retorna caminhos dentro de ffmpeg-temp.
function Find-ToolBin([string]$binName, [string[]]$candidates) {
    foreach ($c in $candidates) {
        if ((Test-Path $c) -and ($c -notmatch [regex]::Escape("ffmpeg-temp"))) {
            return $c
        }
    }
    $found = Get-ChildItem $ToolsSource -Filter $binName -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch [regex]::Escape("ffmpeg-temp") } |
        Select-Object -First 1
    if ($found) { return $found.FullName }
    return $null
}

# yt-dlp
$YtDlpSrc = Find-ToolBin "yt-dlp.exe" @((Join-Path $ToolsSource "yt-dlp.exe"))
if ($YtDlpSrc) {
    Copy-Item -Path $YtDlpSrc -Destination $ToolsDest -Force
    $YtDlpCopied = $true
    Write-Ok "yt-dlp.exe copiado de: $YtDlpSrc"
} else {
    Write-Warn "yt-dlp.exe nao encontrado."
}

# ffmpeg
$FfmpegSrc = Find-ToolBin "ffmpeg.exe" @(
    (Join-Path $ToolsSource "ffmpeg.exe"),
    (Join-Path $ToolsSource "ffmpeg\ffmpeg.exe"),
    (Join-Path $ToolsSource "ffmpeg\bin\ffmpeg.exe")
)
if ($FfmpegSrc) {
    Copy-Item -Path $FfmpegSrc -Destination $ToolsDest -Force
    $FfmpegCopied = $true
    Write-Ok "ffmpeg.exe copiado de: $FfmpegSrc"
} else {
    Write-Warn "ffmpeg.exe nao encontrado."
}

# ffprobe
$FfprobeSrc = Find-ToolBin "ffprobe.exe" @(
    (Join-Path $ToolsSource "ffprobe.exe"),
    (Join-Path $ToolsSource "ffmpeg\ffprobe.exe"),
    (Join-Path $ToolsSource "ffmpeg\bin\ffprobe.exe")
)
if ($FfprobeSrc) {
    Copy-Item -Path $FfprobeSrc -Destination $ToolsDest -Force
    $FfprobeCopied = $true
    Write-Ok "ffprobe.exe copiado de: $FfprobeSrc"
} else {
    Write-Warn "ffprobe.exe nao encontrado."
}

# Remover qualquer arquivo bloqueado que tenha escapado
foreach ($f in (Get-ChildItem $ToolsDest -File -ErrorAction SilentlyContinue)) {
    if (Test-IsBlocked $f.Name) {
        Remove-Item $f.FullName -Force
        Write-Warn "Arquivo bloqueado removido do destino: $($f.Name)"
    }
}

# RequireFfmpeg: falhar se ffmpeg ou ffprobe ausentes
if ($RequireFfmpeg) {
    $ffmpegMissing = (-not $FfmpegCopied) -or (-not $FfprobeCopied)
    if ($ffmpegMissing) {
        Pop-Location
        if (-not $FfmpegCopied)  { Write-Fail "RequireFfmpeg: ffmpeg.exe nao encontrado. Build cancelado." }
        if (-not $FfprobeCopied) { Write-Fail "RequireFfmpeg: ffprobe.exe nao encontrado. Build cancelado." }
        exit 1
    }
    Write-Ok "RequireFfmpeg: ffmpeg.exe e ffprobe.exe presentes."
}

# ---------------------------------------------------------------------------
# 7. README_PORTABLE.txt
# ---------------------------------------------------------------------------
Write-Step "Gerando README_PORTABLE.txt..."

$ReadmePath = Join-Path $PackageDir "README_PORTABLE.txt"
$readmeLines = [System.Collections.Generic.List[string]]::new()
$readmeLines.Add("ClipFlow Downloader - Pacote Portatil Windows")
$readmeLines.Add("=============================================")
$readmeLines.Add("")
$readmeLines.Add("COMO USAR")
$readmeLines.Add("---------")
$readmeLines.Add('1. Extraia esta pasta para qualquer local do seu computador.')
$readmeLines.Add('2. Abra o arquivo "clipflow_downloader.exe" (ou o executavel presente nesta pasta).')
$readmeLines.Add('3. O aplicativo nao precisa de instalacao.')
$readmeLines.Add("")
$readmeLines.Add("YOUTUBE COM PROTECAO ANTI-BOT")
$readmeLines.Add("------------------------------")
$readmeLines.Add("O YouTube pode bloquear downloads diretos. Para contornar isso de forma segura:")
$readmeLines.Add("")
$readmeLines.Add("1. Instale o Firefox (https://www.mozilla.org/) e faca login na sua conta do YouTube.")
$readmeLines.Add("2. Deixe o Firefox aberto enquanto usa o ClipFlow Downloader.")
$readmeLines.Add('3. Nas preferencias do app, ative a opcao "Usar sessao do Firefox para YouTube".')
$readmeLines.Add("")
$readmeLines.Add("O app usara a sua sessao local do Firefox para autenticar os downloads.")
$readmeLines.Add("Nenhum dado de login e transmitido a terceiros.")
$readmeLines.Add("")
$readmeLines.Add("FFMPEG (NECESSARIO PARA QUALIDADE ALTA)")
$readmeLines.Add("----------------------------------------")
$readmeLines.Add("Para baixar videos em qualidade alta (ex: 1080p), o ffmpeg.exe e obrigatorio.")
$readmeLines.Add("Ele e usado para juntar a trilha de video e audio separadas.")
$readmeLines.Add("")
$readmeLines.Add("O ffprobe.exe e recomendado para inspecao de arquivos de midia.")
$readmeLines.Add("")
$readmeLines.Add("Se o pacote nao incluir ffmpeg.exe, coloque manualmente em:")
$readmeLines.Add("    tools\ffmpeg\bin\ffmpeg.exe")
$readmeLines.Add("    tools\ffmpeg\bin\ffprobe.exe")
$readmeLines.Add("")
$readmeLines.Add("Baixe em: https://ffmpeg.org/download.html")
$readmeLines.Add("")
$readmeLines.Add("DENO (RECOMENDADO)")
$readmeLines.Add("------------------")
$readmeLines.Add("Para melhor compatibilidade com o YouTube, instale o Deno:")
$readmeLines.Add("    https://deno.land/")
$readmeLines.Add("")
$readmeLines.Add("Deno e utilizado internamente pelo yt-dlp para alguns extratores avancados.")
$readmeLines.Add("")
$readmeLines.Add("AVISOS IMPORTANTES")
$readmeLines.Add("------------------")
$readmeLines.Add("- Nao compartilhe sua pasta de perfil do Firefox nem arquivos de cookies.")
$readmeLines.Add("- Nao distribua esta pasta contendo dados de sessao pessoais.")
$readmeLines.Add("- Use o ClipFlow Downloader apenas com conteudo que voce tem direito de baixar:")
$readmeLines.Add("  conteudo proprio, conteudo com licenca aberta ou conteudo para uso pessoal")
$readmeLines.Add("  autorizado pelo detentor dos direitos.")
$readmeLines.Add("- O uso indevido para baixar conteudo protegido sem autorizacao e de")
$readmeLines.Add("  responsabilidade exclusiva do usuario.")
$readmeLines.Add("")
$readmeLines.Add("SUPORTE")
$readmeLines.Add("-------")
$readmeLines.Add("Repositorio: https://github.com/brunonaval/clipflow-downloader")

[System.IO.File]::WriteAllText($ReadmePath, ($readmeLines -join "`r`n"), [System.Text.Encoding]::UTF8)
Write-Ok "README_PORTABLE.txt gerado."

# ---------------------------------------------------------------------------
# 8. Criar ZIP
# ---------------------------------------------------------------------------
Write-Step "Compactando pacote em ZIP..."

$ZipPath = Join-Path $DistRoot "$PackageName.zip"
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($PackageDir, $ZipPath)
Write-Ok "ZIP criado: $ZipPath"

# ---------------------------------------------------------------------------
# 9. SHA256 externo
# ---------------------------------------------------------------------------
Write-Step "Calculando SHA256 do ZIP..."

$ZipHash    = Get-Sha256 $ZipPath
$Sha256Path = Join-Path $DistRoot "$PackageName.sha256.txt"
$sha256Line = "SHA256  $PackageName.zip"
$sha256Detail = "$ZipHash  $PackageName.zip"
[System.IO.File]::WriteAllText($Sha256Path, "$sha256Line`r`n$sha256Detail`r`n", [System.Text.Encoding]::UTF8)
Write-Ok "SHA256 gerado: $Sha256Path"
Write-Ok "Hash: $ZipHash"

# ---------------------------------------------------------------------------
# 10. RELEASE_MANIFEST.txt
# ---------------------------------------------------------------------------
Write-Step "Gerando RELEASE_MANIFEST.txt..."

$ExeName = Get-ChildItem $PackageDir -Filter "*.exe" -File |
    Where-Object { $_.Name -notmatch "vc_redist" } |
    Select-Object -First 1 -ExpandProperty Name

$GeneratedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

$manifestLines = [System.Collections.Generic.List[string]]::new()
$manifestLines.Add("RELEASE MANIFEST - ClipFlow Downloader")
$manifestLines.Add("======================================")
$manifestLines.Add("App          : ClipFlow Downloader")
$manifestLines.Add("Versao       : $Version")
$manifestLines.Add("Gerado em    : $GeneratedAt")
$manifestLines.Add("Executavel   : $(if ($ExeName) { $ExeName } else { '(nao encontrado)' })")
$manifestLines.Add("")
$manifestLines.Add("ARQUIVOS PRINCIPAIS")
$manifestLines.Add("-------------------")

# executavel
if ($ExeName -and (Test-Path (Join-Path $PackageDir $ExeName))) {
    $manifestLines.Add("  [OK] $ExeName")
} else {
    $manifestLines.Add("  [AUSENTE] executavel nao encontrado")
}

# pasta data
if (Test-Path (Join-Path $PackageDir "data")) {
    $manifestLines.Add("  [OK] data\")
} else {
    $manifestLines.Add("  [AUSENTE] data\")
}

# flutter_windows.dll
if (Test-Path (Join-Path $PackageDir "flutter_windows.dll")) {
    $manifestLines.Add("  [OK] flutter_windows.dll")
} else {
    $manifestLines.Add("  [N/A] flutter_windows.dll (nao encontrado)")
}

# tools
foreach ($t in @("tools\yt-dlp.exe","tools\ffmpeg.exe","tools\ffprobe.exe")) {
    if (Test-Path (Join-Path $PackageDir $t)) {
        $manifestLines.Add("  [OK] $t")
    } else {
        $manifestLines.Add("  [AUSENTE] $t")
    }
}

# README_PORTABLE.txt
if (Test-Path (Join-Path $PackageDir "README_PORTABLE.txt")) {
    $manifestLines.Add("  [OK] README_PORTABLE.txt")
} else {
    $manifestLines.Add("  [AUSENTE] README_PORTABLE.txt")
}

$manifestLines.Add("")
$manifestLines.Add("ZIP")
$manifestLines.Add("---")
$manifestLines.Add("  Arquivo : $PackageName.zip")
$manifestLines.Add("  SHA256  : $ZipHash")
$manifestLines.Add("")
$manifestLines.Add("SEGURANCA")
$manifestLines.Add("---------")
$manifestLines.Add("  Cookies e perfis de navegador NAO sao incluidos neste pacote.")
$manifestLines.Add("  Nunca distribua arquivos de sessao ou credenciais pessoais.")

$ManifestPath = Join-Path $PackageDir "RELEASE_MANIFEST.txt"
[System.IO.File]::WriteAllText($ManifestPath, ($manifestLines -join "`r`n"), [System.Text.Encoding]::UTF8)
Write-Ok "RELEASE_MANIFEST.txt gerado."

# ---------------------------------------------------------------------------
# 11. Verificar pacote portavel
# ---------------------------------------------------------------------------
Write-Step "Verificando pacote portavel..."

$VerifyScript = Join-Path $PSScriptRoot "verify_windows_portable.ps1"
if (Test-Path $VerifyScript) {
    powershell -NoProfile -ExecutionPolicy Bypass -File $VerifyScript -PackagePath $PackageDir
    if ($LASTEXITCODE -ne 0) {
        Pop-Location
        Write-Fail "Verificacao do pacote portavel falhou. Build abortado."
        exit 1
    }
    Write-Ok "Verificacao do pacote portavel: OK"
} else {
    Write-Warn "verify_windows_portable.ps1 nao encontrado -- verificacao ignorada."
}

# ---------------------------------------------------------------------------
# 12. Resumo final
# ---------------------------------------------------------------------------
Pop-Location

Write-Host ""
Write-Host "============================================================" -ForegroundColor White
Write-Host "  BUILD PORTATIL CONCLUIDO" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor White
Write-Host "  Pasta portavel : $PackageDir"
Write-Host "  ZIP            : $ZipPath"
Write-Host "  SHA256         : $Sha256Path"
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
