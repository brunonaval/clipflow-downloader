# Build Portátil Windows — ClipFlow Downloader

## Como gerar

```powershell
# Da raiz do projeto:
.\scripts\build_windows_portable.ps1 -Version "1.0.0"

# Pular testes (build rápido):
.\scripts\build_windows_portable.ps1 -Version "preview" -SkipTests
```

O script gera:
- `dist/ClipFlow-Downloader-portable-<version>/` — pasta portátil pronta
- `dist/ClipFlow-Downloader-portable-<version>.zip` — zip para distribuição

## Como testar

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

> **Nota:** `tools/ffmpeg-temp/` é **sempre ignorado** pelo script de build.
> Coloque o FFmpeg em `tools/ffmpeg/bin/` para empacotamento automático.

## Aviso — Firefox e cookies

O app pode usar a sessão local do Firefox para autenticar no YouTube.
**Nunca inclua** cookies, `cookies.txt` ou pastas de perfil de navegador no repositório ou no pacote distribuído.
O `.gitignore` já protege esses arquivos.

## Aviso — Deno

Deno não é empacotado. O usuário deve instalar separadamente se quiser compatibilidade máxima com extratores do yt-dlp.

## O que este release NÃO é

Este é um pacote **portátil** (extrair e executar), não um instalador Windows (`.msi`/`.exe` de setup).
