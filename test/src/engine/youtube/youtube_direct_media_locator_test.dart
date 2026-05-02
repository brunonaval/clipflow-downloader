import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/youtube/youtube_direct_media_locator.dart';

void main() {
  group('YouTubeDirectMediaLocator', () {
    const locator = YouTubeDirectMediaLocator();

    test('retorna referencia para formato com url direta', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"streamingData":{"formats":[{"itag":18,"mimeType":"video/mp4","url":"https://media.example/video.mp4?token=abc"}]}};</script>';

      final result = locator.locateDirectMedia(html: html, formatId: '18');

      expect(result, isNotNull);
      expect(result!.formatId, '18');
      expect(result.fileExtension, 'mp4');
      expect(result.safeHostLabel, 'media.example');
    });

    test('retorna null para signatureCipher', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"streamingData":{"adaptiveFormats":[{"itag":140,"mimeType":"audio/mp4","signatureCipher":"url=https%3A%2F%2Fmedia.example%2Fa.m4a&sp=s&sig=abc"}]}};</script>';

      final result = locator.locateDirectMedia(html: html, formatId: '140');

      expect(result, isNull);
    });

    test('retorna null para cipher', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"streamingData":{"adaptiveFormats":[{"itag":141,"mimeType":"audio/mp4","cipher":"url=https%3A%2F%2Fmedia.example%2Fa.m4a&sp=s&sig=abc"}]}};</script>';

      final result = locator.locateDirectMedia(html: html, formatId: '141');

      expect(result, isNull);
    });

    test('retorna null para formato inexistente', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"streamingData":{"formats":[{"itag":18,"mimeType":"video/mp4","url":"https://media.example/video.mp4"}]}};</script>';

      final result = locator.locateDirectMedia(html: html, formatId: '999');

      expect(result, isNull);
    });

    test('fileExtension vem de mimeType', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"streamingData":{"adaptiveFormats":[{"itag":251,"mimeType":"audio/webm","url":"https://media.example/audio.webm"}]}};</script>';

      final result = locator.locateDirectMedia(html: html, formatId: '251');

      expect(result, isNotNull);
      expect(result!.fileExtension, 'webm');
    });

    test('safeHostLabel vem do host', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"streamingData":{"formats":[{"itag":22,"mimeType":"video/mp4","url":"https://rr1---sn.example.googlevideo.com/videoplayback?id=abc"}]}};</script>';

      final result = locator.locateDirectMedia(html: html, formatId: '22');

      expect(result, isNotNull);
      expect(result!.safeHostLabel, 'rr1---sn.example.googlevideo.com');
    });

    test('nao expoe URL em labels', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"streamingData":{"formats":[{"itag":18,"mimeType":"video/mp4","url":"https://media.example/video.mp4?token=abc"}]}};</script>';

      final result = locator.locateDirectMedia(html: html, formatId: '18');

      expect(result, isNotNull);
      expect(result!.safeHostLabel.contains('token='), isFalse);
    });
  });
}
