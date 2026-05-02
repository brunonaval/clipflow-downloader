import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/downloads/download_item.dart';
import 'package:clipflow_downloader/src/downloads/download_options.dart';
import 'package:clipflow_downloader/src/downloads/download_queue_controller.dart';

void main() {
  group('DownloadQueueController', () {
    test('initialization keeps provided items and count', () {
      final initialItems = [
        DownloadItem(
          id: '1',
          title: 'Item 1',
          durationLabel: '-',
          sizeLabel: '-',
          formatLabel: 'MP4',
          qualityLabel: '720p',
          fpsLabel: '-',
          sourceLabel: '-',
        ),
      ];
      final controller = DownloadQueueController(initialItems: initialItems);

      expect(controller.itemCount, 1);
      expect(controller.items.length, 1);
      expect(controller.items.first.id, '1');
    });

    test('items getter is externally immutable', () {
      final controller = DownloadQueueController();
      expect(
        () => controller.items.add(
          DownloadItem(
            id: 'x',
            title: 'X',
            durationLabel: '-',
            sizeLabel: '-',
            formatLabel: 'MP4',
            qualityLabel: '720p',
            fpsLabel: '-',
            sourceLabel: '-',
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('itemCountLabel uses singular and plural forms', () {
      final controller = DownloadQueueController();
      expect(controller.itemCountLabel, '0 itens');

      controller.addMockAuthorizedLink();
      expect(controller.itemCountLabel, '1 item');

      controller.addMockAuthorizedLink();
      expect(controller.itemCountLabel, '2 itens');
    });

    test('addMockAuthorizedLink inserts at top and returns created item', () {
      final controller = DownloadQueueController(
        initialItems: [
          DownloadItem(
            id: 'base',
            title: 'Base',
            durationLabel: '-',
            sizeLabel: '-',
            formatLabel: 'MP4',
            qualityLabel: '720p',
            fpsLabel: '-',
            sourceLabel: '-',
          ),
        ],
      );

      final created = controller.addMockAuthorizedLink(
        sourceUrl: 'https://example.com/video',
        transferType: DownloadTransferType.audio,
        formatLabel: 'MP3',
        qualityLabel: '1080p',
        outputFolderLabel: 'Downloads',
      );

      expect(controller.itemCount, 2);
      expect(controller.items.first, same(created));
      expect(created.status, DownloadStatus.queued);
      expect(created.progress, 0);
      expect(created.sourceUrl, 'https://example.com/video');
      expect(created.formatLabel, 'MP3');
      expect(created.qualityLabel, '1080p');
      expect(created.sourceLabel, contains('Downloads'));
      expect(created.title, startsWith('Novo link autorizado #'));
    });

    test('resetForTesting replaces list, updates count and keeps immutability', () {
      final controller = DownloadQueueController();
      controller.addMockAuthorizedLink();

      final replacement = [
        DownloadItem(
          id: 'new-1',
          title: 'New 1',
          durationLabel: '-',
          sizeLabel: '-',
          formatLabel: 'MP4',
          qualityLabel: '480p',
          fpsLabel: '-',
          sourceLabel: '-',
        ),
        DownloadItem(
          id: 'new-2',
          title: 'New 2',
          durationLabel: '-',
          sizeLabel: '-',
          formatLabel: 'MP4',
          qualityLabel: '480p',
          fpsLabel: '-',
          sourceLabel: '-',
        ),
      ];

      controller.resetForTesting(replacement);

      expect(controller.itemCount, 2);
      expect(controller.items.map((e) => e.id).toList(), ['new-1', 'new-2']);
      expect(
        () => controller.items.removeAt(0),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
