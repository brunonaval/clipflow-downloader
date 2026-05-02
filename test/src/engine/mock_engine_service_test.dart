import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/downloads/download_format_option.dart';
import 'package:clipflow_downloader/src/engine/engine_command_plan.dart';
import 'package:clipflow_downloader/src/engine/mock_engine_service.dart';

void main() {
  group('MockEngineService', () {
    const service = MockEngineService();

    test('analyzeMockUrl retorna titulo mockado', () {
      final result = service.analyzeMockUrl(sourceUrl: 'https://example.com');
      expect(result.title, 'Link autorizado analisado');
    });

    test('analyzeMockUrl retorna 4 formatos', () {
      final result = service.analyzeMockUrl();
      expect(result.formats, hasLength(4));
    });

    test('recommendedFormatId e video-mp4-1080p', () {
      final result = service.analyzeMockUrl();
      expect(result.recommendedFormatId, 'video-mp4-1080p');
    });

    test('formato recomendado existe e isRecommended e true', () {
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

    test('lista de formatos e imutavel para uso basico', () {
      final result = service.analyzeMockUrl();
      expect(
        () => result.formats.add(result.formats.first),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('buildMockDownloadPlan para video retorna type download', () {
      final plan = service.buildMockDownloadPlan(
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

      expect(plan.type, EngineCommandPlanType.download);
    });

    test('plano de video contem --format', () {
      final plan = service.buildMockDownloadPlan(
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

    test('plano de audio contem --extract-audio', () {
      final plan = service.buildMockDownloadPlan(
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

    test('plano de legenda contem --subtitles e --text-only', () {
      final plan = service.buildMockDownloadPlan(
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

      expect(plan.arguments, contains('--subtitles'));
      expect(plan.arguments, contains('--text-only'));
    });

    test('plano usa Motor interno como engineLabel', () {
      final plan = service.buildMockDownloadPlan(
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

      expect(plan.engineLabel, 'Motor interno');
    });

    test('plan.isExecutable e false', () {
      final plan = service.buildMockDownloadPlan(
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
