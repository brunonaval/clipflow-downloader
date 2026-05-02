import '../../downloads/download_format_option.dart';
import '../internal_engine_analysis_result.dart';
import 'youtube_format_descriptor.dart';
import 'youtube_html_metadata_parser.dart';
import 'youtube_media_candidate.dart';
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
    YouTubeHtmlMetadataParser metadataParser =
        const YouTubeHtmlMetadataParser(),
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
        directDownloadUri: null,
      );
    }

    final formats = metadata.formatDescriptors.isNotEmpty
        ? _formatOptionsFromDescriptors(metadata.formatDescriptors)
        : _buildMockFormats();

    return InternalEngineAnalysisResult(
      title: metadata.title,
      durationLabel: metadata.durationLabel,
      sourceLabel: 'YouTube metadata extraído · $outputFolderLabel',
      formats: formats,
      recommendedFormatId: formats.first.id,
      canDownloadDirectly: false,
      directDownloadUri: null,
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
      directDownloadUri: null,
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

  List<DownloadFormatOption> _formatOptionsFromDescriptors(
    List<YouTubeFormatDescriptor> descriptors,
  ) {
    final valid = descriptors.where((d) => d.isPlayableDescriptor).toList();
    if (valid.isEmpty) return _buildMockFormats();

    final withRank = valid.map((descriptor) {
      final rank = _priorityRank(descriptor);
      return (descriptor, rank);
    }).toList()..sort((a, b) => a.$2.compareTo(b.$2));

    final filtered = withRank
        .where((pair) => pair.$1.kind != YouTubeFormatKind.unknown)
        .map((pair) => pair.$1)
        .toList();

    final base = filtered.isNotEmpty
        ? filtered
        : withRank.map((pair) => pair.$1).toList();

    final selected = base.take(8).toList();
    final options = <DownloadFormatOption>[];

    for (var i = 0; i < selected.length; i++) {
      final descriptor = selected[i];
      final kind = switch (descriptor.kind) {
        YouTubeFormatKind.audio => DownloadFormatKind.audio,
        YouTubeFormatKind.subtitles => DownloadFormatKind.subtitles,
        _ => DownloadFormatKind.video,
      };

      final label = _optionLabel(descriptor);
      final candidateLabel = _candidateLabel(descriptor.mediaCandidate);
      final details = candidateLabel == null
          ? descriptor.detailsLabel
          : '${descriptor.detailsLabel} · $candidateLabel';

      options.add(
        DownloadFormatOption(
          id: descriptor.id,
          kind: kind,
          label: label,
          formatLabel: descriptor.extension,
          qualityLabel: descriptor.qualityLabel,
          sizeLabel: descriptor.sizeLabel,
          detailsLabel: details,
          isRecommended: i == 0,
        ),
      );
    }

    return options.isEmpty ? _buildMockFormats() : options;
  }

  String? _candidateLabel(YouTubeMediaCandidate? candidate) {
    if (candidate == null) return null;
    return switch (candidate.kind) {
      YouTubeMediaCandidateKind.direct => 'URL direta detectada',
      YouTubeMediaCandidateKind.requiresSignature => 'exige assinatura',
      YouTubeMediaCandidateKind.unavailable => 'sem URL direta',
    };
  }

  int _priorityRank(YouTubeFormatDescriptor descriptor) {
    final ext = descriptor.extension.toUpperCase();
    return switch (descriptor.kind) {
      YouTubeFormatKind.muxed when ext == 'MP4' => 0,
      YouTubeFormatKind.muxed => 1,
      YouTubeFormatKind.video when ext == 'MP4' => 2,
      YouTubeFormatKind.video when ext == 'WEBM' => 3,
      YouTubeFormatKind.video => 4,
      YouTubeFormatKind.audio when ext == 'M4A' => 5,
      YouTubeFormatKind.audio when ext == 'WEBM' => 6,
      YouTubeFormatKind.audio => 7,
      YouTubeFormatKind.subtitles => 8,
      YouTubeFormatKind.unknown => 9,
    };
  }

  String _optionLabel(YouTubeFormatDescriptor descriptor) {
    final ext = descriptor.extension.toUpperCase();
    return switch (descriptor.kind) {
      YouTubeFormatKind.audio => 'Áudio $ext',
      YouTubeFormatKind.video when descriptor.hasAudio =>
        'Vídeo $ext ${descriptor.qualityLabel}',
      YouTubeFormatKind.video =>
        'Vídeo $ext ${descriptor.qualityLabel} sem áudio',
      YouTubeFormatKind.muxed => 'Vídeo $ext ${descriptor.qualityLabel}',
      YouTubeFormatKind.subtitles => 'Legendas $ext',
      YouTubeFormatKind.unknown => 'Formato $ext ${descriptor.qualityLabel}',
    };
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
