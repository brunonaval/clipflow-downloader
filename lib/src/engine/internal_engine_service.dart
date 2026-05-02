import '../downloads/download_format_option.dart';
import 'internal_engine_analysis_result.dart';
import 'internal_engine_source.dart';
import 'youtube/youtube_extractor.dart';

class InternalEngineService {
  const InternalEngineService({
    YouTubeExtractor youtubeExtractor = const YouTubeExtractor(),
  }) : _youtubeExtractor = youtubeExtractor;

  final YouTubeExtractor _youtubeExtractor;

  InternalEngineSource classifyUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return const InternalEngineSource(
        uri: null,
        kind: InternalEngineSourceKind.unsupported,
        label: 'URL vazia',
      );
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return const InternalEngineSource(
        uri: null,
        kind: InternalEngineSourceKind.unsupported,
        label: 'URL inválida',
      );
    }

    if (_youtubeExtractor.isYouTubeUrl(trimmed)) {
      return InternalEngineSource(
        uri: uri,
        kind: InternalEngineSourceKind.webpage,
        label: 'YouTube detectado',
      );
    }

    final path = uri.path.toLowerCase();
    const directExtensions = <String>{
      '.mp4',
      '.webm',
      '.m4v',
      '.mov',
      '.mp3',
      '.m4a',
      '.aac',
      '.wav',
      '.ogg',
      '.srt',
      '.vtt',
    };

    for (final ext in directExtensions) {
      if (path.endsWith(ext)) {
        return InternalEngineSource(
          uri: uri,
          kind: InternalEngineSourceKind.directFile,
          label: 'Arquivo direto detectado',
        );
      }
    }

    return InternalEngineSource(
      uri: uri,
      kind: InternalEngineSourceKind.webpage,
      label: 'Página detectada',
    );
  }

  InternalEngineAnalysisResult analyzeUrl({
    required String rawUrl,
    String outputFolderLabel = 'Vídeos',
  }) {
    final source = classifyUrl(rawUrl);

    if (source.kind == InternalEngineSourceKind.unsupported) {
      return const InternalEngineAnalysisResult(
        title: 'URL não suportada',
        durationLabel: '--:--',
        sourceLabel: 'URL não suportada pelo motor interno',
        formats: [],
        recommendedFormatId: null,
        canDownloadDirectly: false,
      );
    }

    final youtubeResult = _youtubeExtractor.analyzeUrlMock(
      rawUrl: rawUrl,
      outputFolderLabel: outputFolderLabel,
    );
    if (youtubeResult != null) {
      return youtubeResult;
    }

    if (source.kind == InternalEngineSourceKind.directFile) {
      final uri = source.uri!;
      final ext = _fileExtension(uri.path);
      final format = _directFormatForExtension(ext);
      return InternalEngineAnalysisResult(
        title: _titleFromUri(uri),
        durationLabel: '--:--',
        sourceLabel: 'Análise interna concluída · $outputFolderLabel',
        formats: [format],
        recommendedFormatId: format.id,
        canDownloadDirectly: true,
      );
    }

    const formats = [
      DownloadFormatOption(
        id: 'internal-web-video-1080p',
        kind: DownloadFormatKind.video,
        label: 'Vídeo MP4 1080p',
        formatLabel: 'MP4',
        qualityLabel: '1080p',
        sizeLabel: '24 MB',
        detailsLabel: 'Formato sugerido para extractor futuro',
        isRecommended: true,
      ),
      DownloadFormatOption(
        id: 'internal-web-video-720p',
        kind: DownloadFormatKind.video,
        label: 'Vídeo MP4 720p',
        formatLabel: 'MP4',
        qualityLabel: '720p',
        sizeLabel: '16 MB',
        detailsLabel: 'Formato alternativo para extractor futuro',
      ),
      DownloadFormatOption(
        id: 'internal-web-audio-m4a',
        kind: DownloadFormatKind.audio,
        label: 'Áudio M4A',
        formatLabel: 'M4A',
        qualityLabel: 'Áudio',
        sizeLabel: '5 MB',
        detailsLabel: 'Opção de áudio para extractor futuro',
      ),
      DownloadFormatOption(
        id: 'internal-web-subtitles-srt',
        kind: DownloadFormatKind.subtitles,
        label: 'Legendas SRT',
        formatLabel: 'SRT',
        qualityLabel: 'Texto',
        sizeLabel: '120 KB',
        detailsLabel: 'Legendas para extractor futuro',
      ),
    ];

    return InternalEngineAnalysisResult(
      title: 'Página reconhecida',
      durationLabel: '03:21',
      sourceLabel: 'Página reconhecida para extractor futuro · $outputFolderLabel',
      formats: formats,
      recommendedFormatId: formats.first.id,
      canDownloadDirectly: false,
    );
  }

  String _fileExtension(String path) {
    final lower = path.toLowerCase();
    final dot = lower.lastIndexOf('.');
    if (dot < 0 || dot == lower.length - 1) return '';
    return lower.substring(dot);
  }

  String _titleFromUri(Uri uri) {
    final fileName = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    if (fileName.isEmpty) return 'Arquivo direto';
    return Uri.decodeComponent(fileName);
  }

  DownloadFormatOption _directFormatForExtension(String ext) {
    if (ext == '.srt' || ext == '.vtt') {
      final format = ext.substring(1).toUpperCase();
      return DownloadFormatOption(
        id: 'direct-$format',
        kind: DownloadFormatKind.subtitles,
        label: 'Legenda $format',
        formatLabel: format,
        qualityLabel: 'Texto',
        sizeLabel: '--',
        detailsLabel: 'Arquivo de legenda direta',
        isRecommended: true,
      );
    }

    if (ext == '.mp3' ||
        ext == '.m4a' ||
        ext == '.aac' ||
        ext == '.wav' ||
        ext == '.ogg') {
      final format = ext.substring(1).toUpperCase();
      return DownloadFormatOption(
        id: 'direct-$format',
        kind: DownloadFormatKind.audio,
        label: 'Áudio $format',
        formatLabel: format,
        qualityLabel: 'Áudio',
        sizeLabel: '--',
        detailsLabel: 'Arquivo de áudio direto',
        isRecommended: true,
      );
    }

    final format = ext.isEmpty ? 'MP4' : ext.substring(1).toUpperCase();
    return DownloadFormatOption(
      id: 'direct-$format',
      kind: DownloadFormatKind.video,
      label: 'Vídeo $format',
      formatLabel: format,
      qualityLabel: 'Original',
      sizeLabel: '--',
      detailsLabel: 'Arquivo de vídeo direto',
      isRecommended: true,
    );
  }
}
