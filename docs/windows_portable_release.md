# Build Portátil Windows — ClipFlow Downloader

## Como gerar

```powershell
# Build padrão com testes:
.\scripts\build_windows_portable.ps1 -Version "1.0.0"

# Build rápido sem testes:
.\scripts\build_windows_portable.ps1 -Version "preview" -SkipTests

# Build com FFmpeg obrigatório (falha se ffmpeg/ffprobe ausentes):
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_windows_portable.ps1 -Version "0.1.0-preview" -RequireFfmpeg
```

O script gera:
- `dist/ClipFlow-Downloader-portable-<version>/` — pasta portátil pronta
- `dist/ClipFlow-Downloader-portable-<version>.zip` — zip para distribuição
- `dist/ClipFlow-Downloader-portable-<version>.sha256.txt` — hash do zip
- `RELEASE_MANIFEST.txt` dentro da pasta portátil

> **Importante:** `dist/`, `*.zip` e `*.sha256.txt` **não devem ser commitados**.
> O `.gitignore` já os ignora.

## Como validar o pacote

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_windows_portable.ps1 -PackagePath "dist\ClipFlow-Downloader-portable-0.1.0-preview"
```

O script de verificação valida:
- executável presente na raiz
- pasta `data\` presente
- `README_PORTABLE.txt` e `RELEASE_MANIFEST.txt` presentes
- `tools\yt-dlp.exe`, `tools\ffmpeg.exe`, `tools\ffprobe.exe` presentes
- ausência de cookies, perfis de navegador e pasta `.git`

Retorna exit code `0` (OK) ou `1` (falhou).

## Como testar manualmente

1. Extraia o zip em outra máquina ou pasta limpa.
2. Execute `clipflow_downloader.exe`.
3. Teste download simples e download de playlist.
4. Para YouTube: abra Firefox logado no YouTube, ative **"Usar sessão do Firefox para YouTube"** nas preferências do app.

## Dependências externas

| Ferramenta | Caminhos aceitos (ordem de busca) | Uso |
|------------|-----------------------------------|-----|
| `yt-dlp.exe` | `tools/yt-dlp.exe` | Motor de download de vídeo |
| `ffmpeg.exe` | `tools/ffmpeg.exe` → `tools/ffmpeg/ffmpeg.exe` → `tools/ffmpeg/bin/ffmpeg.exe` → busca recursiva em `tools/ffmpeg/` | **Obrigatório** para qualidade alta (merge vídeo+áudio) |
| `ffprobe.exe` | `tools/ffprobe.exe` → `tools/ffmpeg/ffprobe.exe` → `tools/ffmpeg/bin/ffprobe.exe` → busca recursiva em `tools/ffmpeg/` | Recomendado para inspeção de mídia |
| Deno | PATH do sistema | Compatibilidade avançada com YouTube |

> `tools/ffmpeg-temp/` é **sempre ignorado** pelo script de build.
> Coloque o FFmpeg em `tools/ffmpeg/bin/` para empacotamento automático.

## Aviso — Firefox e cookies

O app pode usar a sessão local do Firefox para autenticar no YouTube.
**Nunca inclua** cookies, `cookies.txt` ou pastas de perfil de navegador no repositório ou no pacote distribuído.
O `.gitignore` já protege esses arquivos.

## Aviso — Deno

Deno não é empacotado. O usuário deve instalar separadamente se quiser compatibilidade máxima com extratores do yt-dlp.

## O que este release NÃO é

Este é um pacote **portátil** (extrair e executar), não um instalador Windows (`.msi`/`.exe` de setup).
