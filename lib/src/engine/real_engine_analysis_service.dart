import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../downloads/download_format_option.dart';
import 'engine_analysis_result.dart';
import 'engine_settings.dart';

class EngineAnalysisException implements Exception {
  final String message;
  const EngineAnalysisException(this.message);

  @override
  String toString() => message;
}

class RealEngineAnalysisService {
  const RealEngineAnalysisService();

  Future<EngineAnalysisResult> analyzeUrl({
    required EngineSettings settings,
    required String sourceUrl,
    String outputFolderLabel = 'Vídeos',
  }) async {
    final executable = _resolveExecutable(settings);
    final safeUrl = sourceUrl.trim();

    if (safeUrl.isEmpty) {
      throw const EngineAnalysisException('URL vazia para análise');
    }
    if (!_isHttpUrl(safeUrl)) {
      throw const EngineAnalysisException('Informe um link http/https válido');
    }

    ProcessResult processResult;
    try {
      processResult = await Process.run(executable, [
        '--dump-json',
        '--no-playlist',
        '--skip-download',
        safeUrl,
      ]).timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw const EngineAnalysisException('Tempo limite na análise real');
    } catch (_) {
      throw const EngineAnalysisException('Falha ao executar o motor externo');
    }

    if (processResult.exitCode != 0) {
      final stderrText = processResult.stderr.toString().trim();
      final stdoutText = processResult.stdout.toString().trim();
      final details = stderrText.isNotEmpty ? stderrText : stdoutText;
      throw EngineAnalysisException(
        details.isEmpty ? 'Motor retornou erro na análise real' : details,
      );
    }

    final stdoutText = processResult.stdout.toString().trim();
    if (stdoutText.isEmpty) {
      throw const EngineAnalysisException('Motor não retornou metadados');
    }

    dynamic jsonData;
    try {
      jsonData = jsonDecode(stdoutText);
    } catch (_) {
      throw const EngineAnalysisException('Metadados retornados são inválidos');
    }

    if (jsonData is! Map<String, dynamic>) {
      throw const EngineAnalysisException('Formato de metadados não suportado');
    }

    final title = jsonData['title']?.toString().trim();
    final durationLabel = _formatDuration(jsonData['duration']);
    final formats = _mapFormats(jsonData['formats']);
    final recommendedId = formats.firstWhere((f) => f.isRecommended).id;

    return EngineAnalysisResult(
      title: (title == null || title.isEmpty) ? 'Mídia analisada' : title,
      durationLabel: durationLabel,
      sourceLabel: 'Análise real concluída · $outputFolderLabel',
      formats: formats,
      recommendedFormatId: recommendedId,
    );
  }

  String _resolveExecutable(EngineSettings settings) {
    if (settings.useSystemExecutable) {
      return switch (settings.engineType) {
        EngineType.ytDlp => 'yt-dlp',
        EngineType.youtubeDl => 'youtube-dl',
        EngineType.custom => _requireCustomPath(settings.executablePath),
      };
    }
    return _requireCustomPath(settings.executablePath);
  }

  String _requireCustomPath(String executablePath) {
    final trimmed = executablePath.trim();
    if (trimmed.isEmpty) {
      throw const EngineAnalysisException(
        'Configure o caminho do executável customizado',
      );
    }
    return trimmed;
  }

  bool _isHttpUrl(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  String _formatDuration(dynamic durationValue) {
    if (durationValue is! num) return '--:--';
    final total = durationValue.round();
    if (total <= 0) return '--:--';
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  List<DownloadFormatOption> _mapFormats(dynamic formatsValue) {
    if (formatsValue is! List) {
      return [_fallbackFormat()];
    }

    final mapped = <DownloadFormatOption>[];
    for (final raw in formatsValue) {
      if (raw is! Map) continue;

      final ext = raw['ext']?.toString().toLowerCase() ?? '';
      if (ext != 'mp4' && ext != 'm4a' && ext != 'webm') continue;

      final formatId = raw['format_id']?.toString().trim();
      if (formatId == null || formatId.isEmpty) continue;

      final height = _asInt(raw['height']);
      final vcodec = raw['vcodec']?.toString().toLowerCase() ?? '';
      final acodec = raw['acodec']?.toString().toLowerCase() ?? '';
      final isAudioOnly = vcodec == 'none' || (height == null && ext == 'm4a');

      final kind = isAudioOnly
          ? DownloadFormatKind.audio
          : DownloadFormatKind.video;
      final quality = isAudioOnly
          ? 'Áudio'
          : (height == null ? 'Auto' : '${height}p');
      final label = isAudioOnly ? 'Áudio ${ext.toUpperCase()}' : 'Vídeo ${ext.toUpperCase()} $quality';
      final sizeLabel = _sizeLabel(raw['filesize'] ?? raw['filesize_approx']);
      final details = isAudioOnly
          ? 'Faixa de áudio (${acodec == 'none' ? ext : acodec})'
          : 'Vídeo ${vcodec == 'none' ? ext : vcodec}';

      mapped.add(
        DownloadFormatOption(
          id: formatId,
          kind: kind,
          label: label,
          formatLabel: ext.toUpperCase(),
          qualityLabel: quality,
          sizeLabel: sizeLabel,
          detailsLabel: details,
          isRecommended: false,
        ),
      );
    }

    if (mapped.isEmpty) {
      return [_fallbackFormat()];
    }

    mapped.sort((a, b) {
      final aScore = _formatScore(a);
      final bScore = _formatScore(b);
      return bScore.compareTo(aScore);
    });

    final limited = mapped.take(6).toList();
    final recommended = limited.first;
    limited[0] = DownloadFormatOption(
      id: recommended.id,
      kind: recommended.kind,
      label: recommended.label,
      formatLabel: recommended.formatLabel,
      qualityLabel: recommended.qualityLabel,
      sizeLabel: recommended.sizeLabel,
      detailsLabel: recommended.detailsLabel,
      isRecommended: true,
    );
    return limited;
  }

  int _formatScore(DownloadFormatOption option) {
    var score = 0;
    if (option.kind == DownloadFormatKind.video) score += 1000;
    if (option.formatLabel == 'MP4') score += 100;
    if (option.formatLabel == 'M4A') score += 80;
    if (option.formatLabel == 'WEBM') score += 60;
    final qualityDigits = RegExp(r'(\d{3,4})').firstMatch(option.qualityLabel);
    if (qualityDigits != null) {
      score += int.tryParse(qualityDigits.group(1)!) ?? 0;
    }
    return score;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }

  String _sizeLabel(dynamic value) {
    if (value is! num || value <= 0) return '--';
    final bytes = value.toDouble();
    if (bytes < 1024) return '${bytes.round()} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  DownloadFormatOption _fallbackFormat() {
    return const DownloadFormatOption(
      id: 'best',
      kind: DownloadFormatKind.video,
      label: 'Melhor formato disponível',
      formatLabel: 'auto',
      qualityLabel: 'auto',
      sizeLabel: '--',
      detailsLabel: 'Selecionado pelo motor',
      isRecommended: true,
    );
  }
}
