import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/youtube/youtube_extractor.dart';

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
  });
}
