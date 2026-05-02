import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/downloads/download_format_option.dart';
import 'package:clipflow_downloader/src/engine/engine_settings.dart';
import 'package:clipflow_downloader/src/engine/mock_engine_service.dart';

void main() {
  group('MockEngineService', () {
    const service = MockEngineService();

    test('analyzeMockUrl retorna título mockado', () {
      final result = service.analyzeMockUrl(sourceUrl: 'https://example.com');
      expect(result.title, 'Link autorizado analisado');
    });

    test('analyzeMockUrl retorna 4 formatos', () {
      final result = service.analyzeMockUrl();
      expect(result.formats, hasLength(4));
    });

    test('recommendedFormatId é video-mp4-1080p', () {
      final result = service.analyzeMockUrl();
      expect(result.recommendedFormatId, 'video-mp4-1080p');
    });

    test('formato recomendado existe e isRecommended é true', () {
      final result = service.analyzeMockUrl();
      final recommended = result.formats.firstWhere(
        (f) => f.id == result.recommendedFormatId,
      );
      expect(recommended.isRecommended, isTrue);
    });

    test('sourceLabel inclui a pasta informada', () {
      final result = service.analyzeMockUrl(outputFolderLabel: 'Downloads');
      expect(result.sourceLabel, contains('Downloads'));
    });

    test('lista de formatos é imutável para uso básico', () {
      final result = service.analyzeMockUrl();
      expect(
        () => result.formats.add(result.formats.first),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('buildMockDownloadPlan para vídeo retorna type download', () {
      final plan = service.buildMockDownloadPlan(
        settings: const EngineSettings(),
        sourceUrl: 'https://example.com/video',
        selectedFormat: const DownloadFormatOption(
          id: 'video-mp4-1080p',
          kind: DownloadFormatKind.video,
          label: 'Vídeo MP4 1080p',
          formatLabel: 'MP4',
          qualityLabel: '1080p',
          sizeLabel: '24 MB',
          detailsLabel: 'Vídeo com áudio em MP4',
        ),
      );

      expect(plan.type, isNotNull);
      expect(plan.type.name, 'download');
    });

    test('plano de vídeo contém --format', () {
      final plan = service.buildMockDownloadPlan(
        settings: const EngineSettings(),
        sourceUrl: 'https://example.com/video',
        selectedFormat: const DownloadFormatOption(
          id: 'video-mp4-1080p',
          kind: DownloadFormatKind.video,
          label: 'Vídeo MP4 1080p',
          formatLabel: 'MP4',
          qualityLabel: '1080p',
          sizeLabel: '24 MB',
          detailsLabel: 'Vídeo com áudio em MP4',
        ),
      );

      expect(plan.arguments, contains('--format'));
    });

    test('plano de áudio contém --extract-audio', () {
      final plan = service.buildMockDownloadPlan(
        settings: const EngineSettings(),
        sourceUrl: 'https://example.com/video',
        selectedFormat: const DownloadFormatOption(
          id: 'audio-m4a',
          kind: DownloadFormatKind.audio,
          label: 'Áudio M4A',
          formatLabel: 'M4A',
          qualityLabel: 'Áudio',
          sizeLabel: '5 MB',
          detailsLabel: 'Somente áudio',
        ),
      );

      expect(plan.arguments, contains('--extract-audio'));
    });

    test('plano de legenda contém --write-subs e --skip-download', () {
      final plan = service.buildMockDownloadPlan(
        settings: const EngineSettings(),
        sourceUrl: 'https://example.com/video',
        selectedFormat: const DownloadFormatOption(
          id: 'subtitles-srt',
          kind: DownloadFormatKind.subtitles,
          label: 'Legendas SRT',
          formatLabel: 'SRT',
          qualityLabel: 'Texto',
          sizeLabel: '120 KB',
          detailsLabel: 'Legendas mockadas',
        ),
      );

      expect(plan.arguments, contains('--write-subs'));
      expect(plan.arguments, contains('--skip-download'));
    });

    test('plano usa settings.engineLabel', () {
      final plan = service.buildMockDownloadPlan(
        settings: const EngineSettings(engineType: EngineType.youtubeDl),
        sourceUrl: 'https://example.com/video',
        selectedFormat: const DownloadFormatOption(
          id: 'video-mp4-720p',
          kind: DownloadFormatKind.video,
          label: 'Vídeo MP4 720p',
          formatLabel: 'MP4',
          qualityLabel: '720p',
          sizeLabel: '16 MB',
          detailsLabel: 'Arquivo menor em MP4',
        ),
      );

      expect(plan.executableLabel, 'youtube-dl');
    });

    test('plan.isExecutable é false', () {
      final plan = service.buildMockDownloadPlan(
        settings: const EngineSettings(),
        sourceUrl: 'https://example.com/video',
        selectedFormat: const DownloadFormatOption(
          id: 'video-mp4-1080p',
          kind: DownloadFormatKind.video,
          label: 'Vídeo MP4 1080p',
          formatLabel: 'MP4',
          qualityLabel: '1080p',
          sizeLabel: '24 MB',
          detailsLabel: 'Vídeo com áudio em MP4',
        ),
      );

      expect(plan.isExecutable, isFalse);
    });
  });
}
