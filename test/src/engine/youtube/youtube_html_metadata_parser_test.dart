import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/youtube/youtube_html_metadata_parser.dart';

void main() {
  group('YouTubeHtmlMetadataParser', () {
    const parser = YouTubeHtmlMetadataParser();

    test('parse extrai title de ytInitialPlayerResponse', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"videoDetails":{"title":"Meu Video","lengthSeconds":"201","author":"Canal","thumbnail":{"thumbnails":[{"url":"https://img/1.jpg"}]}},"playabilityStatus":{"status":"OK"}};</script>';
      final result = parser.parse(html: html, videoId: 'abc123');
      expect(result, isNotNull);
      expect(result!.title, 'Meu Video');
    });

    test('parse extrai durationLabel de lengthSeconds', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"videoDetails":{"title":"Video","lengthSeconds":"201"}};</script>';
      final result = parser.parse(html: html, videoId: 'abc123');
      expect(result, isNotNull);
      expect(result!.durationLabel, '03:21');
    });

    test('parse extrai author', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"videoDetails":{"title":"Video","author":"Canal X"}};</script>';
      final result = parser.parse(html: html, videoId: 'abc123');
      expect(result, isNotNull);
      expect(result!.author, 'Canal X');
    });

    test('parse extrai thumbnailUrl', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"videoDetails":{"title":"Video","thumbnail":{"thumbnails":[{"url":"https://img/1.jpg"},{"url":"https://img/2.jpg"}]}}};</script>';
      final result = parser.parse(html: html, videoId: 'abc123');
      expect(result, isNotNull);
      expect(result!.thumbnailUrl, 'https://img/2.jpg');
    });

    test('parse marca isLive quando isLiveContent true', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"videoDetails":{"title":"Live","isLiveContent":true}};</script>';
      final result = parser.parse(html: html, videoId: 'abc123');
      expect(result, isNotNull);
      expect(result!.isLive, isTrue);
    });

    test('parse marca isPlayable false para LOGIN_REQUIRED', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"videoDetails":{"title":"Video"},"playabilityStatus":{"status":"LOGIN_REQUIRED"}};</script>';
      final result = parser.parse(html: html, videoId: 'abc123');
      expect(result, isNotNull);
      expect(result!.isPlayable, isFalse);
    });

    test('parse marca isPlayable false para UNPLAYABLE', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"videoDetails":{"title":"Video"},"playabilityStatus":{"status":"UNPLAYABLE"}};</script>';
      final result = parser.parse(html: html, videoId: 'abc123');
      expect(result, isNotNull);
      expect(result!.isPlayable, isFalse);
    });

    test('fallback para og:title funciona', () {
      const html = '<meta property="og:title" content="Titulo OG">';
      final result = parser.parse(html: html, videoId: 'abc123');
      expect(result, isNotNull);
      expect(result!.title, 'Titulo OG');
    });

    test('fallback para title funciona', () {
      const html = '<html><head><title>Titulo Pagina</title></head></html>';
      final result = parser.parse(html: html, videoId: 'abc123');
      expect(result, isNotNull);
      expect(result!.title, 'Titulo Pagina');
    });

    test('html sem titulo retorna null', () {
      const html = '<html><head></head><body>sem metadados</body></html>';
      final result = parser.parse(html: html, videoId: 'abc123');
      expect(result, isNull);
    });
  });
}
