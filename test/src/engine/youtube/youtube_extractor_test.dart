import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/youtube/youtube_extractor.dart';
import 'package:clipflow_downloader/src/engine/youtube/youtube_format_descriptor.dart';
import 'package:clipflow_downloader/src/engine/youtube/youtube_html_metadata_parser.dart';
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

    test('analyzeUrlMock retorna resultado para URL YouTube valida', () {
      final result = extractor.analyzeUrlMock(
        rawUrl: 'https://www.youtube.com/watch?v=abc123',
      );
      expect(result, isNotNull);
      expect(result!.title, contains('YouTube'));
    });

    test('analyzeUrlMock retorna null para URL nao YouTube', () {
      final result = extractor.analyzeUrlMock(rawUrl: 'https://example.com');
      expect(result, isNull);
    });

    test('resultado tem canDownloadDirectly false', () {
      final result = extractor.analyzeUrlMock(
        rawUrl: 'https://youtu.be/abc123',
      );
      expect(result, isNotNull);
      expect(result!.canDownloadDirectly, isFalse);
    });

    test('resultado tem formatos mockados', () {
      final result = extractor.analyzeUrlMock(
        rawUrl: 'https://youtu.be/abc123',
      );
      expect(result, isNotNull);
      expect(result!.formats, hasLength(4));
    });

    test('resultado tem recommendedFormatId', () {
      final result = extractor.analyzeUrlMock(
        rawUrl: 'https://youtu.be/abc123',
      );
      expect(result, isNotNull);
      expect(result!.recommendedFormatId, isNotNull);
    });

    test('sourceLabel contem YouTube', () {
      final result = extractor.analyzeUrlMock(
        rawUrl: 'https://youtu.be/abc123',
      );
      expect(result, isNotNull);
      expect(result!.sourceLabel, contains('YouTube'));
    });

    test(
      'analyzeUrlMetadata usa descriptors para criar DownloadFormatOption',
      () async {
        const metadata = YouTubeVideoMetadata(
          videoId: 'abc123',
          title: 'Titulo real',
          durationLabel: '04:20',
          formatDescriptors: [
            YouTubeFormatDescriptor(
              id: '18',
              kind: YouTubeFormatKind.muxed,
              mimeType: 'video/mp4',
              extension: 'MP4',
              qualityLabel: '360p',
              bitrateLabel: '500 kbps',
              sizeLabel: '10 MB',
              detailsLabel: 'YouTube · itag 18 · vídeo+áudio',
              hasAudio: true,
              hasVideo: true,
            ),
            YouTubeFormatDescriptor(
              id: '251',
              kind: YouTubeFormatKind.audio,
              mimeType: 'audio/webm',
              extension: 'WEBM',
              qualityLabel: 'Áudio',
              bitrateLabel: '160 kbps',
              sizeLabel: '2 MB',
              detailsLabel: 'YouTube · itag 251 · áudio',
              hasAudio: true,
              hasVideo: false,
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
        expect(result!.formats, hasLength(2));
        expect(result.formats.first.id, '18');
        expect(result.formats.first.formatLabel, 'MP4');
        expect(result.formats.last.kind.name, 'audio');
      },
    );

    test('primeiro formato e recomendado', () async {
      const metadata = YouTubeVideoMetadata(
        videoId: 'abc123',
        title: 'Titulo real',
        durationLabel: '04:20',
        formatDescriptors: [
          YouTubeFormatDescriptor(
            id: '22',
            kind: YouTubeFormatKind.muxed,
            mimeType: 'video/mp4',
            extension: 'MP4',
            qualityLabel: '720p',
            bitrateLabel: '--',
            sizeLabel: '--',
            detailsLabel: '',
            hasAudio: true,
            hasVideo: true,
          ),
          YouTubeFormatDescriptor(
            id: '137',
            kind: YouTubeFormatKind.video,
            mimeType: 'video/mp4',
            extension: 'MP4',
            qualityLabel: '1080p',
            bitrateLabel: '--',
            sizeLabel: '--',
            detailsLabel: '',
            hasAudio: false,
            hasVideo: true,
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
      expect(result!.formats.first.isRecommended, isTrue);
      expect(
        result.formats.skip(1).every((f) => f.isRecommended == false),
        isTrue,
      );
    });

    test('opcoes geradas preservam qualidade e formato', () async {
      const metadata = YouTubeVideoMetadata(
        videoId: 'abc123',
        title: 'Titulo real',
        durationLabel: '04:20',
        formatDescriptors: [
          YouTubeFormatDescriptor(
            id: '137',
            kind: YouTubeFormatKind.video,
            mimeType: 'video/mp4',
            extension: 'MP4',
            qualityLabel: '1080p',
            bitrateLabel: '--',
            sizeLabel: '--',
            detailsLabel: '',
            hasAudio: false,
            hasVideo: true,
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
      expect(result!.formats.first.formatLabel, 'MP4');
      expect(result.formats.first.qualityLabel, '1080p');
    });

    test('quando metadata nao tem descriptors usa mock fallback', () async {
      const metadata = YouTubeVideoMetadata(
        videoId: 'abc123',
        title: 'Titulo real',
        durationLabel: '04:20',
      );
      final metadataExtractor = YouTubeExtractor(
        fetcher: const _FakeFetcher('<html>ok</html>'),
        metadataParser: const _FakeParser(metadata),
      );

      final result = await metadataExtractor.analyzeUrlMetadata(
        rawUrl: 'https://www.youtube.com/watch?v=abc123',
      );

      expect(result, isNotNull);
      expect(result!.formats, hasLength(4));
      expect(result.formats.first.id, 'yt-video-mp4-1080p');
    });

    test(
      'analyzeUrlMetadata retorna formatos vazios para nao reproduzivel',
      () async {
        const metadata = YouTubeVideoMetadata(
          videoId: 'abc123',
          title: 'Bloqueado',
          durationLabel: '--:--',
          isPlayable: false,
        );
        final metadataExtractor = YouTubeExtractor(
          fetcher: const _FakeFetcher('<html>ok</html>'),
          metadataParser: const _FakeParser(metadata),
        );

        final result = await metadataExtractor.analyzeUrlMetadata(
          rawUrl: 'https://www.youtube.com/watch?v=abc123',
        );

        expect(result, isNotNull);
        expect(result!.formats, isEmpty);
        expect(result.sourceLabel, contains('não reproduzível'));
      },
    );
  });
}
