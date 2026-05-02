import '../../downloads/download_format_option.dart';
import '../internal_engine_analysis_result.dart';
import 'youtube_html_metadata_parser.dart';
import 'youtube_page_fetcher.dart';
import 'youtube_url_parser.dart';
import 'youtube_video_reference.dart';

class YouTubeExtractor {
  final YouTubeUrlParser _parser;
  final YouTubePageFetcher _fetcher;
  final YouTubeHtmlMetadataParser _metadataParser;

  const YouTubeExtractor({
    YouTubeUrlParser parser = const YouTubeUrlParser(),
    YouTubePageFetcher fetcher = const YouTubePageFetcher(),
    YouTubeHtmlMetadataParser metadataParser = const YouTubeHtmlMetadataParser(),
  }) : _parser = parser,
       _fetcher = fetcher,
       _metadataParser = metadataParser;

  YouTubeVideoReference? parseReference(String rawUrl) {
    return _parser.parse(rawUrl);
  }

  bool isYouTubeUrl(String rawUrl) {
    return _parser.isYouTubeUrl(rawUrl);
  }

  Future<InternalEngineAnalysisResult?> analyzeUrlMetadata({
    required String rawUrl,
    String outputFolderLabel = 'Vídeos',
  }) async {
    final reference = _parser.parse(rawUrl);
    if (reference == null) return null;

    String html;
    try {
      html = await _fetcher.fetchWatchHtml(reference);
    } on YouTubePageFetchException {
      return null;
    }

    final metadata = _metadataParser.parse(
      html: html,
      videoId: reference.videoId,
    );

    if (metadata == null) {
      return analyzeReferenceMock(
        reference: reference,
        outputFolderLabel: outputFolderLabel,
      );
    }

    if (!metadata.isPlayable) {
      return InternalEngineAnalysisResult(
        title: metadata.title,
        durationLabel: metadata.durationLabel,
        sourceLabel:
            'YouTube reconhecido, mas não reproduzível sem acesso permitido',
        formats: const [],
        recommendedFormatId: null,
        canDownloadDirectly: false,
      );
    }

    final formats = _buildMockFormats();
    return InternalEngineAnalysisResult(
      title: metadata.title,
      durationLabel: metadata.durationLabel,
      sourceLabel: 'YouTube metadata extraído · $outputFolderLabel',
      formats: formats,
      recommendedFormatId: formats.first.id,
      canDownloadDirectly: false,
    );
  }

  InternalEngineAnalysisResult analyzeReferenceMock({
    required YouTubeVideoReference reference,
    String outputFolderLabel = 'Vídeos',
  }) {
    final formats = _buildMockFormats();

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

  List<DownloadFormatOption> _buildMockFormats() {
    return const <DownloadFormatOption>[
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
  }
}
