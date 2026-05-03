import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/youtube/youtube_direct_media_failure.dart';
import 'package:clipflow_downloader/src/engine/youtube/youtube_extractor.dart';
import 'package:clipflow_downloader/src/engine/youtube/youtube_format_descriptor.dart';
import 'package:clipflow_downloader/src/engine/youtube/youtube_html_metadata_parser.dart';
import 'package:clipflow_downloader/src/engine/youtube/youtube_media_candidate.dart';
import 'package:clipflow_downloader/src/engine/youtube/youtube_page_fetcher.dart';
import 'package:clipflow_downloader/src/engine/youtube/youtube_video_metadata.dart';
import 'package:clipflow_downloader/src/engine/youtube/youtube_video_reference.dart';

class _FakeFetcher extends YouTubePageFetcher {
  final String html;
  const _FakeFetcher(this.html);

  @override
  Future<String> fetchWatchHtml(YouTubeVideoReference reference) async => html;
}

class _FakeParser extends YouTubeHtmlMetadataParser {
  final YouTubeVideoMetadata? metadata;
  const _FakeParser(this.metadata);

  @override
  YouTubeVideoMetadata? parse({required String html, required String videoId}) {
    return metadata;
  }
}

void main() {
  group('YouTubeExtractor', () {
    const extractor = YouTubeExtractor();

    test('parseReference retorna videoId correto', () {
      final ref = extractor.parseReference('https://youtu.be/abc123');
      expect(ref, isNotNull);
      expect(ref!.videoId, 'abc123');
    });

    test('analyzeUrlMock retorna resultado para URL YouTube válida', () {
      final result = extractor.analyzeUrlMock(
        rawUrl: 'https://www.youtube.com/watch?v=abc123',
      );
      expect(result, isNotNull);
      expect(result!.title, contains('YouTube'));
    });

    test('analyzeUrlMock retorna null para URL não YouTube', () {
      final result = extractor.analyzeUrlMock(rawUrl: 'https://example.com');
      expect(result, isNull);
    });

    test('detailsLabel menciona URL direta quando candidate direct', () async {
      const metadata = YouTubeVideoMetadata(
        videoId: 'abc123',
        title: 'Título real',
        durationLabel: '04:20',
        formatDescriptors: [
          YouTubeFormatDescriptor(
            id: '18',
            kind: YouTubeFormatKind.muxed,
            mimeType: 'video/mp4',
            extension: 'MP4',
            qualityLabel: '360p',
            bitrateLabel: '--',
            sizeLabel: '--',
            detailsLabel: 'YouTube · itag 18 · vídeo+áudio',
            hasAudio: true,
            hasVideo: true,
            mediaCandidate: YouTubeMediaCandidate(
              formatId: '18',
              kind: YouTubeMediaCandidateKind.direct,
              safeHostLabel: 'example.com',
              canAttemptDirectDownload: true,
              reasonLabel: 'URL direta detectada pelo player',
            ),
          ),
        ],
      );
      final metadataExtractor = YouTubeExtractor(
        fetcher: const _FakeFetcher('<html>ok</html>'),
        metadataParser: const _FakeParser(metadata),
      );

      final result = await metadataExtractor.analyzeUrlMetadata(
        rawUrl: 'https://www.youtube.com/watch?v=abc123',
      );

      expect(result, isNotNull);
      expect(
        result!.formats.first.detailsLabel,
        contains('URL direta detectada'),
      );
      expect(result.canDownloadDirectly, isFalse);
    });

    test('detailsLabel menciona assinatura quando requiresSignature', () async {
      const metadata = YouTubeVideoMetadata(
        videoId: 'abc123',
        title: 'Título real',
        durationLabel: '04:20',
        formatDescriptors: [
          YouTubeFormatDescriptor(
            id: '140',
            kind: YouTubeFormatKind.audio,
            mimeType: 'audio/mp4',
            extension: 'M4A',
            qualityLabel: 'Áudio',
            bitrateLabel: '--',
            sizeLabel: '--',
            detailsLabel: 'YouTube · itag 140 · áudio',
            hasAudio: true,
            hasVideo: false,
            mediaCandidate: YouTubeMediaCandidate(
              formatId: '140',
              kind: YouTubeMediaCandidateKind.requiresSignature,
              canAttemptDirectDownload: false,
              reasonLabel:
                  'Formato exige assinatura; não suportado nesta versão',
            ),
          ),
        ],
      );
      final metadataExtractor = YouTubeExtractor(
        fetcher: const _FakeFetcher('<html>ok</html>'),
        metadataParser: const _FakeParser(metadata),
      );

      final result = await metadataExtractor.analyzeUrlMetadata(
        rawUrl: 'https://www.youtube.com/watch?v=abc123',
      );

      expect(result, isNotNull);
      expect(result!.formats.first.detailsLabel, contains('exige assinatura'));
      expect(result.canDownloadDirectly, isFalse);
    });

    test(
      'lookupDirectMediaForFormat retorna failure requiresSignature',
      () async {
        final extractorWithHtml = YouTubeExtractor(
          fetcher: const _FakeFetcher(
            '<script>var ytInitialPlayerResponse = {"streamingData":{"adaptiveFormats":[{"itag":140,"mimeType":"audio/mp4","signatureCipher":"url=https%3A%2F%2Fmedia.example%2Fa.m4a&sp=s&sig=abc"}]}};</script>',
          ),
        );

        final result = await extractorWithHtml.lookupDirectMediaForFormat(
          rawUrl: 'https://www.youtube.com/watch?v=abc123',
          formatId: '140',
        );

        expect(result.hasReference, isFalse);
        expect(
          result.failure?.reason,
          YouTubeDirectMediaFailureReason.requiresSignature,
        );
      },
    );

    test('lookupDirectMediaForFormat retorna reference com URL direta', () async {
      final extractorWithHtml = YouTubeExtractor(
        fetcher: const _FakeFetcher(
          '<script>var ytInitialPlayerResponse = {"streamingData":{"formats":[{"itag":18,"mimeType":"video/mp4","url":"https://media.example/video.mp4?token=abc"}]}};</script>',
        ),
      );

      final result = await extractorWithHtml.lookupDirectMediaForFormat(
        rawUrl: 'https://www.youtube.com/watch?v=abc123',
        formatId: '18',
      );

      expect(result.hasReference, isTrue);
      expect(result.reference, isNotNull);
      expect(result.reference!.safeHostLabel, 'media.example');
    });
  });
}
