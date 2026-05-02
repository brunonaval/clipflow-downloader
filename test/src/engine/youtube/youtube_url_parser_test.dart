import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/youtube/youtube_url_parser.dart';
import 'package:clipflow_downloader/src/engine/youtube/youtube_video_reference.dart';

void main() {
  group('YouTubeUrlParser', () {
    const parser = YouTubeUrlParser();

    test('parse watch com www.youtube.com', () {
      final result = parser.parse('https://www.youtube.com/watch?v=abc123');
      expect(result, isNotNull);
      expect(result!.videoId, 'abc123');
      expect(result.kind, YouTubeUrlKind.watch);
    });

    test('parse watch com youtube.com', () {
      final result = parser.parse('https://youtube.com/watch?v=abc123');
      expect(result, isNotNull);
      expect(result!.kind, YouTubeUrlKind.watch);
    });

    test('parse watch com m.youtube.com', () {
      final result = parser.parse('https://m.youtube.com/watch?v=abc123');
      expect(result, isNotNull);
      expect(result!.kind, YouTubeUrlKind.watch);
    });

    test('parse youtu.be', () {
      final result = parser.parse('https://youtu.be/abc123?t=10');
      expect(result, isNotNull);
      expect(result!.videoId, 'abc123');
      expect(result.kind, YouTubeUrlKind.shortLink);
    });

    test('parse shorts', () {
      final result = parser.parse('https://www.youtube.com/shorts/abc123?x=1');
      expect(result, isNotNull);
      expect(result!.videoId, 'abc123');
      expect(result.kind, YouTubeUrlKind.short);
    });

    test('parse embed', () {
      final result = parser.parse('https://youtube.com/embed/abc123#frag');
      expect(result, isNotNull);
      expect(result!.videoId, 'abc123');
      expect(result.kind, YouTubeUrlKind.embed);
    });

    test('retorna null para watch sem v', () {
      expect(parser.parse('https://youtube.com/watch?list=123'), isNull);
    });

    test('retorna null para host nao YouTube', () {
      expect(parser.parse('https://example.com/watch?v=abc123'), isNull);
    });

    test('retorna null para URL vazia', () {
      expect(parser.parse('   '), isNull);
    });

    test('isYouTubeUrl true para URL valida', () {
      expect(parser.isYouTubeUrl('https://youtu.be/abc123'), isTrue);
    });

    test('isYouTubeUrl false para URL invalida', () {
      expect(parser.isYouTubeUrl('nota interna'), isFalse);
    });
  });
}
