#Requires -Version 5.1
<#
.SYNOPSIS
    Valida o conteudo de um pacote portavel Windows do ClipFlow Downloader.

.PARAMETER PackagePath
    Caminho para a pasta portavel a ser verificada. Obrigatorio.

.EXAMPLE
    .\scripts\verify_windows_portable.ps1 -PackagePath "dist\ClipFlow-Downloader-portable-preview"
#>
param(
    [Parameter(Mandatory)]
    [string]$PackagePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$errors = [System.Collections.Generic.List[string]]::new()

function Add-Error([string]$msg) { $errors.Add("  [FALHA] $msg") }
function Write-Check([string]$msg) { Write-Host "  [OK] $msg" -ForegroundColor Green }

Write-Host ""
Write-Host ">>> Verificando pacote portavel: $PackagePath" -ForegroundColor Cyan

# 1. Pasta existe
if (-not (Test-Path $PackagePath -PathType Container)) {
    Write-Host "  [ERRO] PackagePath nao existe ou nao e uma pasta: $PackagePath" -ForegroundColor Red
    exit 1
}
Write-Check "Pasta existe: $PackagePath"

# 2. Executavel principal na raiz (preferir ClipFlowDownloader.exe, aceitar clipflow_downloader.exe como fallback)
$mainExe = $null
if (Test-Path (Join-Path $PackagePath "ClipFlowDownloader.exe")) {
    $mainExe = "ClipFlowDownloader.exe"
} elseif (Test-Path (Join-Path $PackagePath "clipflow_downloader.exe")) {
    $mainExe = "clipflow_downloader.exe"
} else {
    $anyExe = Get-ChildItem $PackagePath -Filter "*.exe" -File |
        Where-Object { $_.Name -notmatch "vc_redist" } |
        Select-Object -First 1
    if ($anyExe) { $mainExe = $anyExe.Name }
}
if ($mainExe) {
    Write-Check "Executavel encontrado: $mainExe"
} else {
    Add-Error "Nenhum executavel principal encontrado na raiz do pacote."
}

# 3. Pasta data
if (Test-Path (Join-Path $PackagePath "data") -PathType Container) {
    Write-Check "Pasta data\ presente."
} else {
    Add-Error "Pasta data\ ausente."
}

# 4. README_PORTABLE.txt
if (Test-Path (Join-Path $PackagePath "README_PORTABLE.txt")) {
    Write-Check "README_PORTABLE.txt presente."
} else {
    Add-Error "README_PORTABLE.txt ausente."
}

# 5. RELEASE_MANIFEST.txt
if (Test-Path (Join-Path $PackagePath "RELEASE_MANIFEST.txt")) {
    Write-Check "RELEASE_MANIFEST.txt presente."
} else {
    Add-Error "RELEASE_MANIFEST.txt ausente."
}

# 6. tools/yt-dlp.exe
if (Test-Path (Join-Path $PackagePath "tools\yt-dlp.exe")) {
    Write-Check "tools\yt-dlp.exe presente."
} else {
    Add-Error "tools\yt-dlp.exe ausente."
}

# 7. tools/ffmpeg.exe
if (Test-Path (Join-Path $PackagePath "tools\ffmpeg.exe")) {
    Write-Check "tools\ffmpeg.exe presente."
} else {
    Add-Error "tools\ffmpeg.exe ausente."
}

# 8. tools/ffprobe.exe
if (Test-Path (Join-Path $PackagePath "tools\ffprobe.exe")) {
    Write-Check "tools\ffprobe.exe presente."
} else {
    Add-Error "tools\ffprobe.exe ausente."
}

# 9. Nenhum arquivo com nome suspeito (cookies, perfis)
$blockedPatterns = @('*cookie*','*cookies*','*firefox-profile*','*browser-profile*')
$allFiles = Get-ChildItem $PackagePath -Recurse -File -ErrorAction SilentlyContinue
foreach ($f in $allFiles) {
    $lower = $f.Name.ToLowerInvariant()
    foreach ($pat in $blockedPatterns) {
        if ($lower -like $pat) {
            Add-Error "Arquivo bloqueado encontrado: $($f.FullName)"
            break
        }
    }
}
$blockedDirs = @('*firefox-profile*','*browser-profile*')
$allDirs = Get-ChildItem $PackagePath -Recurse -Directory -ErrorAction SilentlyContinue
foreach ($d in $allDirs) {
    $lower = $d.Name.ToLowerInvariant()
    foreach ($pat in $blockedDirs) {
        if ($lower -like $pat) {
            Add-Error "Pasta bloqueada encontrada: $($d.FullName)"
            break
        }
    }
}
if ($errors.Count -eq 0 -or ($errors | Where-Object { $_ -match "bloqueado" }).Count -eq 0) {
    Write-Check "Nenhum arquivo de cookie ou perfil de navegador encontrado."
}

# 10. Pasta .git nao existe dentro do pacote
if (Test-Path (Join-Path $PackagePath ".git") -PathType Container) {
    Add-Error "Pasta .git encontrada dentro do pacote. Nao deve ser incluida."
} else {
    Write-Check "Pasta .git ausente (correto)."
}

# ---------------------------------------------------------------------------
# Resultado
# ---------------------------------------------------------------------------
Write-Host ""
if ($errors.Count -eq 0) {
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "  VERIFICACAO OK -- pacote portavel valido." -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host "  VERIFICACAO FALHOU -- $($errors.Count) problema(s) encontrado(s):" -ForegroundColor Red
    foreach ($e in $errors) { Write-Host $e -ForegroundColor Red }
    Write-Host "============================================================" -ForegroundColor Red
    exit 1
}
