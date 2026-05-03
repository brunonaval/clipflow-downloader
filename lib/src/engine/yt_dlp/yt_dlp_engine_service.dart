import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../downloads/download_format_option.dart';
import '../download/internal_download_cancellation.dart';
import '../download/internal_download_progress.dart';
import '../download/internal_download_result.dart';
import 'ffmpeg_executable.dart';
import 'yt_dlp_analysis_result.dart';
import 'yt_dlp_executable.dart';

class YtDlpEngineException implements Exception {
  final String message;
  const YtDlpEngineException(this.message);

  @override
  String toString() => message;
}

class YtDlpEngineService {
  const YtDlpEngineService({
    YtDlpExecutableResolver resolver = const YtDlpExecutableResolver(),
    FfmpegExecutableResolver ffmpegResolver = const FfmpegExecutableResolver(),
    YtDlpProcessRunner runner = const DefaultYtDlpProcessRunner(),
  }) : _resolver = resolver,
       _ffmpegResolver = ffmpegResolver,
       _runner = runner;

  final YtDlpExecutableResolver _resolver;
  final FfmpegExecutableResolver _ffmpegResolver;
  final YtDlpProcessRunner _runner;

  Future<FfmpegExecutable?> resolveFfmpeg() {
    return _ffmpegResolver.resolve();
  }

  Future<YtDlpAnalysisResult> analyzeUrl(String url) async {
    final executable = await _resolver.resolve();
    if (executable == null) {
      throw const YtDlpEngineException(
        'yt-dlp não disponível no sistema ou em tools/yt-dlp.exe.',
      );
    }

    final safeUrl = url.trim();
    if (safeUrl.isEmpty) {
      throw const YtDlpEngineException('URL vazia para análise.');
    }

    ProcessResult result;
    try {
      result = await _runner
          .run(executable.path, [
            '--dump-single-json',
            '--no-playlist',
            '--skip-download',
            safeUrl,
          ])
          .timeout(const Duration(seconds: 45));
    } on TimeoutException {
      throw const YtDlpEngineException('Tempo limite na análise com yt-dlp.');
    } catch (_) {
      throw const YtDlpEngineException(
        'Falha ao executar yt-dlp para análise.',
      );
    }

    final rawJson = result.stdout.toString().trim();
    dynamic decoded;

    if (rawJson.isNotEmpty) {
      try {
        decoded = jsonDecode(rawJson);
      } catch (_) {
        if (result.exitCode != 0) {
          final errorText = _shortError(result.stderr, result.stdout);
          throw YtDlpEngineException('Falha na análise do yt-dlp: $errorText');
        }
        throw const YtDlpEngineException(
          'yt-dlp retornou metadados inválidos para análise.',
        );
      }
    } else if (result.exitCode != 0) {
      final errorText = _shortError(result.stderr, result.stdout);
      throw YtDlpEngineException('Falha na análise do yt-dlp: $errorText');
    } else {
      throw const YtDlpEngineException('yt-dlp não retornou metadados.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const YtDlpEngineException(
        'yt-dlp retornou estrutura inesperada de metadados.',
      );
    }

    final formats = _mapFormats(decoded).take(12).toList();
    final recommendedId = _recommendedFormatId(formats);

    return YtDlpAnalysisResult(
      title: decoded['title']?.toString().trim().isNotEmpty == true
          ? decoded['title'].toString()
          : 'YouTube',
      durationLabel: _durationLabel(decoded['duration']),
      formats: formats,
      recommendedFormatId: recommendedId,
    );
  }

  Future<InternalDownloadResult> download({
    required String url,
    required String formatId,
    String? selectedFormatLabel,
    required String outputTemplate,
    required void Function(InternalDownloadProgress progress) onProgress,
    InternalDownloadCancellation? cancellation,
  }) async {
    final executable = await _resolver.resolve();
    if (executable == null) {
      return const InternalDownloadResult(
        status: InternalDownloadStatus.failed,
        message: 'yt-dlp não disponível no sistema ou em tools/yt-dlp.exe.',
        receivedBytes: 0,
      );
    }

    final safeUrl = url.trim();
    if (safeUrl.isEmpty) {
      return const InternalDownloadResult(
        status: InternalDownloadStatus.failed,
        message: 'URL vazia para download.',
        receivedBytes: 0,
      );
    }

    final selectedIsVideoOnly = _isVideoOnlyFormatId(formatId);
    final isMp4VideoOnly =
        selectedIsVideoOnly &&
        (selectedFormatLabel?.trim().toUpperCase() ?? '') == 'MP4';
    final ffmpegExecutable = await _ffmpegResolver.resolve();
    if (selectedIsVideoOnly && ffmpegExecutable == null) {
      return const InternalDownloadResult(
        status: InternalDownloadStatus.failed,
        message:
            'Este formato contém apenas vídeo e requer FFmpeg para juntar áudio.',
        receivedBytes: 0,
      );
    }

    final arguments = <String>[
      '--newline',
      '--no-playlist',
      '-f',
      selectedIsVideoOnly
          ? (isMp4VideoOnly
                ? '$formatId+bestaudio[ext=m4a]/$formatId+140/$formatId+bestaudio/best'
                : '$formatId+bestaudio/best')
          : formatId,
      if (selectedIsVideoOnly) ...const ['--merge-output-format', 'mp4'],
      if (ffmpegExecutable != null) ...[
        '--ffmpeg-location',
        _ffmpegLocationArgument(ffmpegExecutable.path),
      ],
      '-o',
      outputTemplate,
      safeUrl,
    ];

    Process process;
    try {
      process = await _runner.start(executable.path, arguments);
    } catch (_) {
      return const InternalDownloadResult(
        status: InternalDownloadStatus.failed,
        message: 'Falha ao iniciar processo do yt-dlp.',
        receivedBytes: 0,
      );
    }

    var receivedBytes = 0;
    String lastError = '';

    final stdoutSub = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          final percent = parseProgressPercent(line);
          if (percent != null) {
            final scaled = (percent * 1000000).round();
            receivedBytes = scaled;
            onProgress(
              InternalDownloadProgress(
                receivedBytes: scaled,
                totalBytes: 1000000,
                isDone: percent >= 1.0,
              ),
            );
          }
        });

    final stderrSub = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          final percent = parseProgressPercent(line);
          if (percent != null) {
            final scaled = (percent * 1000000).round();
            receivedBytes = scaled;
            onProgress(
              InternalDownloadProgress(
                receivedBytes: scaled,
                totalBytes: 1000000,
                isDone: percent >= 1.0,
              ),
            );
          } else if (line.trim().isNotEmpty) {
            lastError = line.trim();
          }
        });

    Timer? cancelTimer;
    if (cancellation != null) {
      cancelTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (!cancellation.isCanceled) return;
        process.kill(ProcessSignal.sigterm);
      });
    }

    final exitCode = await process.exitCode;
    await stdoutSub.cancel();
    await stderrSub.cancel();
    cancelTimer?.cancel();

    if (cancellation?.isCanceled ?? false) {
      return InternalDownloadResult(
        status: InternalDownloadStatus.canceled,
        message: 'Download cancelado.',
        receivedBytes: receivedBytes,
      );
    }

    if (exitCode == 0) {
      onProgress(
        const InternalDownloadProgress(
          receivedBytes: 1000000,
          totalBytes: 1000000,
          isDone: true,
        ),
      );
      return const InternalDownloadResult(
        status: InternalDownloadStatus.completed,
        message: 'Download concluído.',
        receivedBytes: 1000000,
      );
    }

    return InternalDownloadResult(
      status: InternalDownloadStatus.failed,
      message: lastError.isNotEmpty
          ? 'Falha no download com yt-dlp: $lastError'
          : 'Falha no download com yt-dlp.',
      receivedBytes: receivedBytes,
    );
  }

  static double? parseProgressPercent(String line) {
    final match = RegExp(
      r'\[download\]\s+([0-9]+(?:\.[0-9]+)?)%',
    ).firstMatch(line);
    if (match == null) return null;
    final value = double.tryParse(match.group(1)!);
    if (value == null) return null;
    return (value / 100).clamp(0.0, 1.0);
  }

  static bool isVideoOnlyOption(DownloadFormatOption option) {
    return option.detailsLabel.contains('[video-only]');
  }

  static bool formatNeedsFfmpeg(String formatId) {
    return _isVideoOnlyFormatId(formatId);
  }

  static bool _isVideoOnlyFormatId(String formatId) {
    const directVideoOnlyIds = <String>{
      '133',
      '134',
      '135',
      '136',
      '137',
      '138',
      '160',
      '212',
      '264',
      '266',
      '271',
      '272',
      '278',
      '298',
      '299',
      '302',
      '303',
      '308',
      '313',
      '315',
      '394',
      '395',
      '396',
      '397',
      '398',
      '399',
      '400',
      '401',
      '402',
    };
    return directVideoOnlyIds.contains(formatId.trim());
  }

  List<DownloadFormatOption> _mapFormats(Map<String, dynamic> json) {
    final rawFormats = json['formats'];
    if (rawFormats is! List) return const [];

    final mapped = <DownloadFormatOption>[];
    for (final raw in rawFormats) {
      if (raw is! Map) continue;

      final map = <String, dynamic>{};
      for (final entry in raw.entries) {
        map[entry.key.toString()] = entry.value;
      }

      final formatId = map['format_id']?.toString().trim();
      if (formatId == null || formatId.isEmpty) continue;
      if (formatId.toLowerCase().startsWith('sb')) continue;

      final extRaw = (map['ext']?.toString().trim().toLowerCase() ?? 'bin');
      if (extRaw == 'mhtml') continue;
      final ext = extRaw.toUpperCase();

      final vcodec = map['vcodec']?.toString() ?? '';
      final acodec = map['acodec']?.toString() ?? '';
      final hasVideo = vcodec.isNotEmpty && vcodec != 'none';
      final hasAudio = acodec.isNotEmpty && acodec != 'none';
      if (!hasVideo && !hasAudio) continue;

      final category = _classifyFormat(hasVideo: hasVideo, hasAudio: hasAudio);
      final kind = category == _YtDlpFormatCategory.audioOnly
          ? DownloadFormatKind.audio
          : DownloadFormatKind.video;

      final quality = _qualityLabel(map, hasVideo);
      final size = _sizeLabel(map['filesize'] ?? map['filesize_approx']);

      final label = switch (category) {
        _YtDlpFormatCategory.muxed => 'Vídeo $ext $quality',
        _YtDlpFormatCategory.videoOnly => 'Vídeo sem áudio — requer FFmpeg',
        _YtDlpFormatCategory.audioOnly => 'Áudio $ext $quality',
      };

      final note = map['format_note']?.toString().trim();
      final baseDetails = note == null || note.isEmpty
          ? 'yt-dlp format $formatId'
          : 'yt-dlp format $formatId · $note';
      final sizeDetails = size == '--' ? '' : ' · $size';

      final details = switch (category) {
        _YtDlpFormatCategory.muxed =>
          '[muxed] $baseDetails$sizeDetails · vídeo+áudio',
        _YtDlpFormatCategory.videoOnly =>
          '[video-only] $baseDetails$sizeDetails · vídeo sem áudio · requer FFmpeg · áudio M4A preferido para MP4',
        _YtDlpFormatCategory.audioOnly =>
          '[audio-only] $baseDetails$sizeDetails · áudio',
      };

      mapped.add(
        DownloadFormatOption(
          id: formatId,
          kind: kind,
          label: label,
          formatLabel: ext,
          qualityLabel: quality,
          sizeLabel: size,
          detailsLabel: details,
        ),
      );
    }

    mapped.sort((a, b) {
      final aRank = _formatPriority(a);
      final bRank = _formatPriority(b);
      if (aRank != bRank) return aRank.compareTo(bRank);
      return a.label.compareTo(b.label);
    });

    final recommendedId = _recommendedFormatId(mapped);
    if (recommendedId != null) {
      for (var i = 0; i < mapped.length; i++) {
        final item = mapped[i];
        if (item.id != recommendedId) continue;
        mapped[i] = DownloadFormatOption(
          id: item.id,
          kind: item.kind,
          label: item.label,
          formatLabel: item.formatLabel,
          qualityLabel: item.qualityLabel,
          sizeLabel: item.sizeLabel,
          detailsLabel: item.detailsLabel,
          isRecommended: true,
        );
        break;
      }
    }

    return mapped;
  }

  int _formatPriority(DownloadFormatOption option) {
    final ext = option.formatLabel.toUpperCase();
    final quality = option.qualityLabel;
    final isVideoOnly = option.detailsLabel.contains('[video-only]');
    final isAudioOnly = option.detailsLabel.contains('[audio-only]');
    final isMuxed = option.detailsLabel.contains('[muxed]');

    if (isMuxed && ext == 'MP4') return _qualityRank(quality);
    if (isMuxed && ext == 'WEBM') return 100 + _qualityRank(quality);
    if (isAudioOnly && ext == 'M4A') return 200;
    if (isAudioOnly && ext == 'WEBM') return 300;
    if (isAudioOnly) return 350;
    if (isVideoOnly) return 400 + _qualityRank(quality);
    return 500;
  }

  String? _recommendedFormatId(List<DownloadFormatOption> options) {
    for (final option in options) {
      if (option.detailsLabel.contains('[video-only]')) continue;
      return option.id;
    }
    return null;
  }

  int _qualityRank(String quality) {
    final numbers = RegExp(r'(\d{3,4})p').firstMatch(quality.toLowerCase());
    final value = numbers == null ? 0 : int.tryParse(numbers.group(1)!) ?? 0;
    if (value >= 2160) return 0;
    if (value >= 1440) return 1;
    if (value >= 1080) return 2;
    if (value >= 720) return 3;
    if (value >= 480) return 4;
    if (value >= 360) return 5;
    if (value > 0) return 6;
    return 9;
  }

  String _durationLabel(Object? rawDuration) {
    final seconds = rawDuration is num
        ? rawDuration.toInt()
        : int.tryParse(rawDuration?.toString() ?? '');
    if (seconds == null || seconds <= 0) return '--:--';

    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _qualityLabel(Map<String, dynamic> map, bool hasVideo) {
    final qualityLabel = map['format_note']?.toString().trim();
    if (qualityLabel != null && qualityLabel.isNotEmpty) return qualityLabel;

    if (hasVideo) {
      final height = map['height'];
      if (height is num && height > 0) return '${height.toInt()}p';
      final resolution = map['resolution']?.toString().trim();
      if (resolution != null && resolution.isNotEmpty) return resolution;
      return 'vídeo';
    }

    final abr = map['abr'];
    if (abr is num && abr > 0) return '${abr.toInt()}k';
    return 'medium';
  }

  String _sizeLabel(Object? raw) {
    final bytes = raw is num
        ? raw.toInt()
        : int.tryParse(raw?.toString() ?? '');
    if (bytes == null || bytes <= 0) return '--';

    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(1)} GB';
  }

  String _shortError(Object? stderr, Object? stdout) {
    final stderrText = stderr?.toString().trim() ?? '';
    if (stderrText.isNotEmpty) return stderrText.split('\n').last.trim();
    final stdoutText = stdout?.toString().trim() ?? '';
    if (stdoutText.isNotEmpty) return stdoutText.split('\n').last.trim();
    return 'erro desconhecido';
  }

  static String _ffmpegLocationArgument(String ffmpegPath) {
    final normalized = ffmpegPath.replaceAll('\\', '/').toLowerCase();
    if (normalized.endsWith('/ffmpeg.exe') || normalized.endsWith('/ffmpeg')) {
      return File(ffmpegPath).parent.path;
    }
    return ffmpegPath;
  }
}

enum _YtDlpFormatCategory { muxed, videoOnly, audioOnly }

_YtDlpFormatCategory _classifyFormat({
  required bool hasVideo,
  required bool hasAudio,
}) {
  if (hasVideo && hasAudio) return _YtDlpFormatCategory.muxed;
  if (hasVideo) return _YtDlpFormatCategory.videoOnly;
  return _YtDlpFormatCategory.audioOnly;
}

abstract class YtDlpProcessRunner {
  const YtDlpProcessRunner();

  Future<ProcessResult> run(String executable, List<String> arguments);

  Future<Process> start(String executable, List<String> arguments);
}

class DefaultYtDlpProcessRunner extends YtDlpProcessRunner {
  const DefaultYtDlpProcessRunner();

  @override
  Future<ProcessResult> run(String executable, List<String> arguments) {
    return Process.run(executable, arguments);
  }

  @override
  Future<Process> start(String executable, List<String> arguments) {
    return Process.start(executable, arguments);
  }
}
