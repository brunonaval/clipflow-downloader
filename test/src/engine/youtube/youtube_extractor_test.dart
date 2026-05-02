import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/youtube/youtube_extractor.dart';
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

    test('analyzeUrlMetadata usa metadados quando playable', () async {
      final metadata = YouTubeVideoMetadata(
        videoId: 'abc123',
        title: 'Titulo real',
        durationLabel: '04:20',
      );
      final metadataExtractor = YouTubeExtractor(
        fetcher: const _FakeFetcher('<html>ok</html>'),
        metadataParser: _FakeParser(metadata),
      );

      final result = await metadataExtractor.analyzeUrlMetadata(
        rawUrl: 'https://www.youtube.com/watch?v=abc123',
      );

      expect(result, isNotNull);
      expect(result!.title, 'Titulo real');
      expect(result.durationLabel, '04:20');
      expect(result.formats, isNotEmpty);
    });

    test('analyzeUrlMetadata retorna formatos vazios para nao reproduzivel', () async {
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
    });
  });
}
