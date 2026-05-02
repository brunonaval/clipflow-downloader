import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/downloads/download_format_option.dart';
import 'package:clipflow_downloader/src/downloads/download_item.dart';
import 'package:clipflow_downloader/src/downloads/download_options.dart';

void main() {
  group('DownloadItem', () {
    test('metadataLabel builds expected string', () {
      final item = DownloadItem(
        id: 'test-1',
        title: 'Test',
        durationLabel: '03:03',
        sizeLabel: '15,7 MB',
        formatLabel: 'MP4',
        qualityLabel: '480p',
        fpsLabel: '25fps',
        sourceLabel: 'Conteúdo autorizado',
      );
      expect(
        item.metadataLabel,
        '03:03 · 15,7 MB · MP4 · 480p · 25fps · Conteúdo autorizado',
      );
    });

    test('transferType defaults to video', () {
      final item = DownloadItem(
        id: 'default-type',
        title: 'Any',
        durationLabel: '-',
        sizeLabel: '-',
        formatLabel: '-',
        qualityLabel: '-',
        fpsLabel: '-',
        sourceLabel: '-',
      );
      expect(item.transferType, DownloadTransferType.video);
    });

    test('availableFormats defaults to empty and selectedFormatId to null', () {
      final item = DownloadItem(
        id: 'defaults',
        title: 'Default',
        durationLabel: '-',
        sizeLabel: '-',
        formatLabel: '-',
        qualityLabel: '-',
        fpsLabel: '-',
        sourceLabel: '-',
      );

      expect(item.availableFormats, isEmpty);
      expect(item.selectedFormatId, isNull);
      expect(item.commandPreviewLabel, isNull);
    });

    test('copyWith preserves fields not overridden', () {
      final item = DownloadItem(
        id: 'test-2',
        title: 'Original',
        durationLabel: '01:00',
        sizeLabel: '10 MB',
        formatLabel: 'MP4',
        qualityLabel: '1080p',
        fpsLabel: '30fps',
        sourceLabel: 'Source',
        status: DownloadStatus.queued,
        progress: 0.0,
      );
      final copied = item.copyWith(title: 'Updated');
      expect(copied.id, 'test-2');
      expect(copied.title, 'Updated');
      expect(copied.formatLabel, 'MP4');
      expect(copied.qualityLabel, '1080p');
      expect(copied.status, DownloadStatus.queued);
      expect(copied.progress, 0.0);
      expect(copied.transferType, DownloadTransferType.video);
    });

    test('copyWith updates transferType', () {
      final item = DownloadItem(
        id: 'type-1',
        title: 'Type',
        durationLabel: '-',
        sizeLabel: '-',
        formatLabel: 'MP4',
        qualityLabel: '720p',
        fpsLabel: '-',
        sourceLabel: '-',
      );
      final copied = item.copyWith(transferType: DownloadTransferType.audio);
      expect(copied.transferType, DownloadTransferType.audio);
    });

    test('copyWith updates availableFormats', () {
      final item = DownloadItem(
        id: 'formats',
        title: 'Formats',
        durationLabel: '-',
        sizeLabel: '-',
        formatLabel: 'MP4',
        qualityLabel: '720p',
        fpsLabel: '-',
        sourceLabel: '-',
      );

      final copied = item.copyWith(
        availableFormats: const [
          DownloadFormatOption(
            id: 'audio-m4a',
            kind: DownloadFormatKind.audio,
            label: 'Áudio M4A',
            formatLabel: 'M4A',
            qualityLabel: 'Áudio',
            sizeLabel: '5 MB',
            detailsLabel: 'Somente áudio',
          ),
        ],
      );

      expect(copied.availableFormats, hasLength(1));
      expect(copied.availableFormats.first.id, 'audio-m4a');
    });

    test('copyWith updates selectedFormatId', () {
      final item = DownloadItem(
        id: 'selected',
        title: 'Selected',
        durationLabel: '-',
        sizeLabel: '-',
        formatLabel: 'MP4',
        qualityLabel: '720p',
        fpsLabel: '-',
        sourceLabel: '-',
      );

      final copied = item.copyWith(selectedFormatId: 'video-mp4-1080p');

      expect(copied.selectedFormatId, 'video-mp4-1080p');
    });

    test('copyWith updates commandPreviewLabel', () {
      final item = DownloadItem(
        id: 'preview',
        title: 'Preview',
        durationLabel: '-',
        sizeLabel: '-',
        formatLabel: 'MP4',
        qualityLabel: '720p',
        fpsLabel: '-',
        sourceLabel: '-',
      );

      final copied = item.copyWith(
        commandPreviewLabel:
            'Motor interno --format video-mp4-1080p https://example.com',
      );

      expect(
        copied.commandPreviewLabel,
        'Motor interno --format video-mp4-1080p https://example.com',
      );
    });

    test('progress is clamped to 0.0 for values below 0', () {
      final item = DownloadItem(
        id: 'low',
        title: 'Low',
        durationLabel: '-',
        sizeLabel: '-',
        formatLabel: '-',
        qualityLabel: '-',
        fpsLabel: '-',
        sourceLabel: '-',
        progress: -0.5,
      );
      expect(item.progress, 0.0);
    });

    test('progress is clamped to 1.0 for values above 1', () {
      final item = DownloadItem(
        id: 'high',
        title: 'High',
        durationLabel: '-',
        sizeLabel: '-',
        formatLabel: '-',
        qualityLabel: '-',
        fpsLabel: '-',
        sourceLabel: '-',
        progress: 1.5,
      );
      expect(item.progress, 1.0);
    });

    test('statusLabel returns "Na fila" for queued status', () {
      final item = DownloadItem(
        id: 'q',
        title: 'Q',
        durationLabel: '-',
        sizeLabel: '-',
        formatLabel: '-',
        qualityLabel: '-',
        fpsLabel: '-',
        sourceLabel: '-',
        status: DownloadStatus.queued,
      );
      expect(item.statusLabel, 'Na fila');
    });

    test('statusLabel returns "Pausado" for paused status', () {
      final item = DownloadItem(
        id: 'p',
        title: 'P',
        durationLabel: '-',
        sizeLabel: '-',
        formatLabel: '-',
        qualityLabel: '-',
        fpsLabel: '-',
        sourceLabel: '-',
        status: DownloadStatus.paused,
      );
      expect(item.statusLabel, 'Pausado');
    });

    test('statusLabel returns correct text for all statuses', () {
      final cases = {
        DownloadStatus.queued: 'Na fila',
        DownloadStatus.analyzing: 'Analisando',
        DownloadStatus.ready: 'Pronto',
        DownloadStatus.downloading: 'Baixando',
        DownloadStatus.paused: 'Pausado',
        DownloadStatus.completed: 'Concluído',
        DownloadStatus.failed: 'Falhou',
        DownloadStatus.canceled: 'Cancelado',
      };
      for (final entry in cases.entries) {
        final item = DownloadItem(
          id: entry.key.name,
          title: '-',
          durationLabel: '-',
          sizeLabel: '-',
          formatLabel: '-',
          qualityLabel: '-',
          fpsLabel: '-',
          sourceLabel: '-',
          status: entry.key,
        );
        expect(item.statusLabel, entry.value, reason: 'status: ${entry.key}');
      }
    });
  });
}
