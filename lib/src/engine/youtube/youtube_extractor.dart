import '../../downloads/download_format_option.dart';
import '../internal_engine_analysis_result.dart';
import 'youtube_url_parser.dart';
import 'youtube_video_reference.dart';

class YouTubeExtractor {
  final YouTubeUrlParser _parser;

  const YouTubeExtractor({
    YouTubeUrlParser parser = const YouTubeUrlParser(),
  }) : _parser = parser;

  YouTubeVideoReference? parseReference(String rawUrl) {
    return _parser.parse(rawUrl);
  }

  bool isYouTubeUrl(String rawUrl) {
    return _parser.isYouTubeUrl(rawUrl);
  }

  InternalEngineAnalysisResult analyzeReferenceMock({
    required YouTubeVideoReference reference,
    String outputFolderLabel = 'Vídeos',
  }) {
    const formats = <DownloadFormatOption>[
      DownloadFormatOption(
        id: 'yt-video-mp4-1080p',
        kind: DownloadFormatKind.video,
        label: 'Vídeo MP4 1080p',
        formatLabel: 'MP4',
        qualityLabel: '1080p',
        sizeLabel: '24 MB',
        detailsLabel: 'Vídeo com áudio em MP4',
        isRecommended: true,
      ),
      DownloadFormatOption(
        id: 'yt-video-mp4-720p',
        kind: DownloadFormatKind.video,
        label: 'Vídeo MP4 720p',
        formatLabel: 'MP4',
        qualityLabel: '720p',
        sizeLabel: '16 MB',
        detailsLabel: 'Arquivo menor em MP4',
      ),
      DownloadFormatOption(
        id: 'yt-audio-m4a',
        kind: DownloadFormatKind.audio,
        label: 'Áudio M4A',
        formatLabel: 'M4A',
        qualityLabel: 'Áudio',
        sizeLabel: '5 MB',
        detailsLabel: 'Somente áudio',
      ),
      DownloadFormatOption(
        id: 'yt-subtitles-srt',
        kind: DownloadFormatKind.subtitles,
        label: 'Legendas SRT',
        formatLabel: 'SRT',
        qualityLabel: 'Texto',
        sizeLabel: '120 KB',
        detailsLabel: 'Legendas mockadas',
      ),
    ];

    return InternalEngineAnalysisResult(
      title: 'Vídeo do YouTube reconhecido',
      durationLabel: '--:--',
      sourceLabel:
          'YouTube reconhecido · extractor interno futuro · $outputFolderLabel',
      formats: formats,
      recommendedFormatId: formats.first.id,
      canDownloadDirectly: false,
    );
  }

  InternalEngineAnalysisResult? analyzeUrlMock({
    required String rawUrl,
    String outputFolderLabel = 'Vídeos',
  }) {
    final reference = _parser.parse(rawUrl);
    if (reference == null) return null;
    return analyzeReferenceMock(
      reference: reference,
      outputFolderLabel: outputFolderLabel,
    );
  }
}
