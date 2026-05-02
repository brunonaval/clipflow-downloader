import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/youtube/youtube_format_descriptor.dart';
import 'package:clipflow_downloader/src/engine/youtube/youtube_html_metadata_parser.dart';
import 'package:clipflow_downloader/src/engine/youtube/youtube_media_candidate.dart';

void main() {
  group('YouTubeHtmlMetadataParser', () {
    const parser = YouTubeHtmlMetadataParser();

    test('parse extrai title de ytInitialPlayerResponse', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"videoDetails":{"title":"Meu Video","lengthSeconds":"201","author":"Canal","thumbnail":{"thumbnails":[{"url":"https://img/1.jpg"}]},"isLiveContent":false},"playabilityStatus":{"status":"OK"}};</script>';
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

    test('parse extrai formatos de streamingData.formats', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"videoDetails":{"title":"Video"},"streamingData":{"formats":[{"itag":18,"mimeType":"video/mp4","qualityLabel":"360p","bitrate":500000,"contentLength":"10485760","audioQuality":"AUDIO_QUALITY_MEDIUM"}]}};</script>';
      final result = parser.parse(html: html, videoId: 'abc123');
      expect(result, isNotNull);
      expect(result!.formatDescriptors, isNotEmpty);
      expect(result.formatDescriptors.first.id, '18');
    });

    test('parse extrai formatos de adaptiveFormats', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"videoDetails":{"title":"Video"},"streamingData":{"adaptiveFormats":[{"itag":251,"mimeType":"audio/webm","bitrate":160000,"contentLength":"2097152","audioQuality":"AUDIO_QUALITY_MEDIUM"}]}};</script>';
      final result = parser.parse(html: html, videoId: 'abc123');
      expect(result, isNotNull);
      expect(result!.formatDescriptors, isNotEmpty);
      expect(result.formatDescriptors.first.id, '251');
    });

    test('formato muxed MP4 vira descriptor muxed', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"videoDetails":{"title":"Video"},"streamingData":{"formats":[{"itag":22,"mimeType":"video/mp4","qualityLabel":"720p","audioQuality":"AUDIO_QUALITY_MEDIUM"}]}};</script>';
      final result = parser.parse(html: html, videoId: 'abc123');
      expect(result, isNotNull);
      expect(result!.formatDescriptors.first.kind, YouTubeFormatKind.muxed);
    });

    test('formato audio/webm vira descriptor audio', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"videoDetails":{"title":"Video"},"streamingData":{"adaptiveFormats":[{"itag":251,"mimeType":"audio/webm","audioQuality":"AUDIO_QUALITY_MEDIUM"}]}};</script>';
      final result = parser.parse(html: html, videoId: 'abc123');
      expect(result, isNotNull);
      expect(result!.formatDescriptors.first.kind, YouTubeFormatKind.audio);
    });

    test('formato video/mp4 sem audio vira descriptor video', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"videoDetails":{"title":"Video"},"streamingData":{"adaptiveFormats":[{"itag":137,"mimeType":"video/mp4","qualityLabel":"1080p"}]}};</script>';
      final result = parser.parse(html: html, videoId: 'abc123');
      expect(result, isNotNull);
      expect(result!.formatDescriptors.first.kind, YouTubeFormatKind.video);
    });

    test('formato com url cria candidate direct com host', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"videoDetails":{"title":"Video"},"streamingData":{"formats":[{"itag":18,"mimeType":"video/mp4","url":"https://rr1---sn.example.googlevideo.com/videoplayback?id=abc","audioQuality":"AUDIO_QUALITY_MEDIUM"}]}};</script>';
      final result = parser.parse(html: html, videoId: 'abc123');
      expect(result, isNotNull);
      final candidate = result!.formatDescriptors.first.mediaCandidate;
      expect(candidate, isNotNull);
      expect(candidate!.kind, YouTubeMediaCandidateKind.direct);
      expect(candidate.safeHostLabel, 'rr1---sn.example.googlevideo.com');
      expect(candidate.canAttemptDirectDownload, isTrue);
    });

    test('formato com signatureCipher cria candidate requiresSignature', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"videoDetails":{"title":"Video"},"streamingData":{"adaptiveFormats":[{"itag":140,"mimeType":"audio/mp4","signatureCipher":"url=https%3A%2F%2Fx&sp=s&sig=abc","audioQuality":"AUDIO_QUALITY_MEDIUM"}]}};</script>';
      final result = parser.parse(html: html, videoId: 'abc123');
      expect(result, isNotNull);
      final candidate = result!.formatDescriptors.first.mediaCandidate;
      expect(candidate, isNotNull);
      expect(candidate!.kind, YouTubeMediaCandidateKind.requiresSignature);
      expect(candidate.canAttemptDirectDownload, isFalse);
    });

    test('formato com cipher cria candidate requiresSignature', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"videoDetails":{"title":"Video"},"streamingData":{"adaptiveFormats":[{"itag":141,"mimeType":"audio/mp4","cipher":"url=https%3A%2F%2Fx&sp=s&sig=abc","audioQuality":"AUDIO_QUALITY_MEDIUM"}]}};</script>';
      final result = parser.parse(html: html, videoId: 'abc123');
      expect(result, isNotNull);
      final candidate = result!.formatDescriptors.first.mediaCandidate;
      expect(candidate, isNotNull);
      expect(candidate!.kind, YouTubeMediaCandidateKind.requiresSignature);
    });

    test('formato sem url ou cipher cria candidate unavailable', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"videoDetails":{"title":"Video"},"streamingData":{"formats":[{"itag":137,"mimeType":"video/mp4","qualityLabel":"1080p"}]}};</script>';
      final result = parser.parse(html: html, videoId: 'abc123');
      expect(result, isNotNull);
      final candidate = result!.formatDescriptors.first.mediaCandidate;
      expect(candidate, isNotNull);
      expect(candidate!.kind, YouTubeMediaCandidateKind.unavailable);
      expect(candidate.canAttemptDirectDownload, isFalse);
    });

    test('descriptor nao expoe URL completa', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"videoDetails":{"title":"Video"},"streamingData":{"formats":[{"itag":18,"mimeType":"video/mp4","url":"https://stream.example/video?token=secret","audioQuality":"AUDIO_QUALITY_MEDIUM"}]}};</script>';
      final result = parser.parse(html: html, videoId: 'abc123');
      expect(result, isNotNull);
      final descriptor = result!.formatDescriptors.first;
      final candidate = descriptor.mediaCandidate;
      expect(candidate, isNotNull);
      expect(candidate!.safeHostLabel, 'stream.example');
      expect(candidate.reasonLabel.contains('token=secret'), isFalse);
      expect(descriptor.detailsLabel.contains('http'), isFalse);
    });

    test('descriptor nao expoe signatureCipher nem cipher', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"videoDetails":{"title":"Video"},"streamingData":{"adaptiveFormats":[{"itag":140,"mimeType":"audio/mp4","signatureCipher":"url=https%3A%2F%2Fx&sp=s&sig=abc","audioQuality":"AUDIO_QUALITY_MEDIUM"}]}};</script>';
      final result = parser.parse(html: html, videoId: 'abc123');
      expect(result, isNotNull);
      final descriptor = result!.formatDescriptors.first;
      final candidate = descriptor.mediaCandidate;
      expect(candidate, isNotNull);
      expect(candidate!.reasonLabel.contains('signatureCipher'), isFalse);
      expect(descriptor.mimeType.contains('signatureCipher'), isFalse);
      expect(descriptor.detailsLabel.contains('cipher'), isFalse);
    });

    test('contentLength vira sizeLabel em MB/KB', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"videoDetails":{"title":"Video"},"streamingData":{"formats":[{"itag":18,"mimeType":"video/mp4","contentLength":"10485760","audioQuality":"AUDIO_QUALITY_MEDIUM"}]}};</script>';
      final result = parser.parse(html: html, videoId: 'abc123');
      expect(result, isNotNull);
      expect(result!.formatDescriptors.first.sizeLabel, contains('MB'));
    });

    test('bitrate vira bitrateLabel em kbps', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"videoDetails":{"title":"Video"},"streamingData":{"formats":[{"itag":18,"mimeType":"video/mp4","bitrate":500000,"audioQuality":"AUDIO_QUALITY_MEDIUM"}]}};</script>';
      final result = parser.parse(html: html, videoId: 'abc123');
      expect(result, isNotNull);
      expect(result!.formatDescriptors.first.bitrateLabel, contains('kbps'));
    });

    test('sem streamingData retorna lista vazia', () {
      const html =
          '<script>var ytInitialPlayerResponse = {"videoDetails":{"title":"Video"}};</script>';
      final result = parser.parse(html: html, videoId: 'abc123');
      expect(result, isNotNull);
      expect(result!.formatDescriptors, isEmpty);
    });
  });
}
