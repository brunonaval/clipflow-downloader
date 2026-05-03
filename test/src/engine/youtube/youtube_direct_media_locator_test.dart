import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/youtube/youtube_direct_media_failure.dart';
import 'package:clipflow_downloader/src/engine/youtube/youtube_direct_media_locator.dart';

void main() {
  group('YouTubeDirectMediaLocator', () {
    const locator = YouTubeDirectMediaLocator();

    test('lookupDirectMedia retorna referência para URL direta válida', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"streamingData":{"formats":[{"itag":18,"mimeType":"video/mp4","url":"https://media.example/video.mp4?token=abc"}]}};</script>';

      final result = locator.lookupDirectMedia(html: html, formatId: '18');

      expect(result.hasReference, isTrue);
      expect(result.reference, isNotNull);
      expect(result.reference!.fileExtension, 'mp4');
      expect(result.reference!.safeHostLabel, 'media.example');
    });

    test('signatureCipher retorna failure requiresSignature', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"streamingData":{"adaptiveFormats":[{"itag":140,"mimeType":"audio/mp4","signatureCipher":"url=https%3A%2F%2Fmedia.example%2Fa.m4a&sp=s&sig=abc"}]}};</script>';

      final result = locator.lookupDirectMedia(html: html, formatId: '140');

      expect(result.reference, isNull);
      expect(
        result.failure?.reason,
        YouTubeDirectMediaFailureReason.requiresSignature,
      );
    });

    test('cipher retorna failure requiresSignature', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"streamingData":{"adaptiveFormats":[{"itag":141,"mimeType":"audio/mp4","cipher":"url=https%3A%2F%2Fmedia.example%2Fa.m4a&sp=s&sig=abc"}]}};</script>';

      final result = locator.lookupDirectMedia(html: html, formatId: '141');

      expect(result.reference, isNull);
      expect(
        result.failure?.reason,
        YouTubeDirectMediaFailureReason.requiresSignature,
      );
    });

    test('sem url retorna failure noDirectUrl', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"streamingData":{"formats":[{"itag":22,"mimeType":"video/mp4"}]}};</script>';

      final result = locator.lookupDirectMedia(html: html, formatId: '22');

      expect(result.reference, isNull);
      expect(
        result.failure?.reason,
        YouTubeDirectMediaFailureReason.noDirectUrl,
      );
    });

    test('formato inexistente retorna failure formatNotFound', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"streamingData":{"formats":[{"itag":18,"mimeType":"video/mp4","url":"https://media.example/video.mp4"}]}};</script>';

      final result = locator.lookupDirectMedia(html: html, formatId: '999');

      expect(result.reference, isNull);
      expect(
        result.failure?.reason,
        YouTubeDirectMediaFailureReason.formatNotFound,
      );
    });

    test('HTML sem player retorna failure unsupported', () {
      const html = '<html><body>sem player</body></html>';

      final result = locator.lookupDirectMedia(html: html, formatId: '18');

      expect(result.reference, isNull);
      expect(
        result.failure?.reason,
        YouTubeDirectMediaFailureReason.unsupported,
      );
    });

    test('url inválida retorna failure invalidUrl', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"streamingData":{"formats":[{"itag":18,"mimeType":"video/mp4","url":"notaurl"}]}};</script>';

      final result = locator.lookupDirectMedia(html: html, formatId: '18');

      expect(result.reference, isNull);
      expect(
        result.failure?.reason,
        YouTubeDirectMediaFailureReason.invalidUrl,
      );
    });

    test(
      'locateDirectMedia mantém compatibilidade retornando apenas reference',
      () {
        const html =
            '<script>var ytInitialPlayerResponse = {"streamingData":{"formats":[{"itag":18,"mimeType":"video/mp4","url":"https://media.example/video.mp4"}]}};</script>';

        final reference = locator.locateDirectMedia(html: html, formatId: '18');

        expect(reference, isNotNull);
        expect(reference!.formatId, '18');
      },
    );
  });
}
