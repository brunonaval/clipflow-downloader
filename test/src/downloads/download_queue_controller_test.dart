import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/downloads/download_item.dart';
import 'package:clipflow_downloader/src/downloads/download_options.dart';
import 'package:clipflow_downloader/src/downloads/download_queue_controller.dart';
import 'package:clipflow_downloader/src/downloads/download_queue_filter.dart';
import 'package:clipflow_downloader/src/engine/engine_settings.dart';

DownloadItem _item({
  required String id,
  required String title,
  DownloadTransferType transferType = DownloadTransferType.video,
  DownloadStatus status = DownloadStatus.queued,
  double progress = 0,
  String sourceLabel = 'Origem',
}) {
  return DownloadItem(
    id: id,
    title: title,
    durationLabel: '01:00',
    sizeLabel: '10 MB',
    formatLabel: 'MP4',
    qualityLabel: '1080p',
    fpsLabel: '30fps',
    sourceLabel: sourceLabel,
    transferType: transferType,
    status: status,
    progress: progress,
  );
}

void main() {
  group('DownloadQueueController', () {
    test('initialization keeps provided items and count', () {
      final initialItems = [_item(id: '1', title: 'Item 1')];
      final controller = DownloadQueueController(initialItems: initialItems);

      expect(controller.itemCount, 1);
      expect(controller.items.length, 1);
      expect(controller.items.first.id, '1');
    });

    test('items getter is externally immutable', () {
      final controller = DownloadQueueController();
      expect(
        () => controller.items.add(_item(id: 'x', title: 'X')),
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

    test('filteredItems all returns every item', () {
      final controller = DownloadQueueController(
        initialItems: [
          _item(
            id: '1',
            title: 'Video',
            transferType: DownloadTransferType.video,
          ),
          _item(
            id: '2',
            title: 'Audio',
            transferType: DownloadTransferType.audio,
          ),
        ],
      );

      final filtered = controller.filteredItems(
        filter: DownloadQueueFilter.all,
      );
      expect(filtered.length, 2);
    });

    test('filteredItems video returns only video items', () {
      final controller = DownloadQueueController(
        initialItems: [
          _item(
            id: '1',
            title: 'Video',
            transferType: DownloadTransferType.video,
          ),
          _item(
            id: '2',
            title: 'Audio',
            transferType: DownloadTransferType.audio,
          ),
        ],
      );

      final filtered = controller.filteredItems(
        filter: DownloadQueueFilter.video,
      );
      expect(filtered.length, 1);
      expect(filtered.first.transferType, DownloadTransferType.video);
    });

    test('filteredItems audio returns only audio items', () {
      final controller = DownloadQueueController(
        initialItems: [
          _item(
            id: '1',
            title: 'Video',
            transferType: DownloadTransferType.video,
          ),
          _item(
            id: '2',
            title: 'Audio',
            transferType: DownloadTransferType.audio,
          ),
        ],
      );

      final filtered = controller.filteredItems(
        filter: DownloadQueueFilter.audio,
      );
      expect(filtered.length, 1);
      expect(filtered.first.transferType, DownloadTransferType.audio);
    });

    test('filteredItems searchQuery filters by title', () {
      final controller = DownloadQueueController(
        initialItems: [
          _item(
            id: '1',
            title: 'Podcast de treino',
            transferType: DownloadTransferType.audio,
          ),
          _item(
            id: '2',
            title: 'Aula de vídeo',
            transferType: DownloadTransferType.video,
          ),
        ],
      );

      final filtered = controller.filteredItems(
        filter: DownloadQueueFilter.all,
        searchQuery: 'podcast',
      );
      expect(filtered.length, 1);
      expect(filtered.first.id, '1');
    });

    test('filteredItems searchQuery filters by metadata/sourceLabel', () {
      final controller = DownloadQueueController(
        initialItems: [
          _item(id: '1', title: 'A', sourceLabel: 'Pasta Downloads'),
          _item(id: '2', title: 'B', sourceLabel: 'Pasta Vídeos'),
        ],
      );

      final filtered = controller.filteredItems(
        filter: DownloadQueueFilter.all,
        searchQuery: 'downloads',
      );
      expect(filtered.length, 1);
      expect(filtered.first.id, '1');
    });

    test('filteredItemCountLabel returns correct label for filters', () {
      final controller = DownloadQueueController(
        initialItems: [
          _item(
            id: '1',
            title: 'Video',
            transferType: DownloadTransferType.video,
          ),
          _item(
            id: '2',
            title: 'Audio',
            transferType: DownloadTransferType.audio,
          ),
        ],
      );

      expect(
        controller.filteredItemCountLabel(filter: DownloadQueueFilter.video),
        '1 item',
      );
      expect(
        controller.filteredItemCountLabel(
          filter: DownloadQueueFilter.playlists,
        ),
        '0 itens',
      );
    });

    test('startItem changes queued to downloading', () {
      final controller = DownloadQueueController(
        initialItems: [
          _item(id: '1', title: 'Item', status: DownloadStatus.queued),
        ],
      );

      final updated = controller.startItem('1');
      expect(updated, isNotNull);
      expect(updated!.status, DownloadStatus.downloading);
    });

    test('pauseItem changes downloading to paused', () {
      final controller = DownloadQueueController(
        initialItems: [
          _item(id: '1', title: 'Item', status: DownloadStatus.downloading),
        ],
      );

      final updated = controller.pauseItem('1');
      expect(updated, isNotNull);
      expect(updated!.status, DownloadStatus.paused);
    });

    test('cancelItem changes downloading to canceled', () {
      final controller = DownloadQueueController(
        initialItems: [
          _item(id: '1', title: 'Item', status: DownloadStatus.downloading),
        ],
      );

      final updated = controller.cancelItem('1');
      expect(updated, isNotNull);
      expect(updated!.status, DownloadStatus.canceled);
    });

    test('removeItem removes and returns item', () {
      final controller = DownloadQueueController(
        initialItems: [_item(id: '1', title: 'Item')],
      );

      final removed = controller.removeItem('1');
      expect(removed, isNotNull);
      expect(removed!.id, '1');
      expect(controller.itemCount, 0);
    });

    test('clearFinishedItems removes completed and canceled', () {
      final controller = DownloadQueueController(
        initialItems: [
          _item(id: '1', title: 'Done', status: DownloadStatus.completed),
          _item(id: '2', title: 'Canceled', status: DownloadStatus.canceled),
          _item(id: '3', title: 'Queued', status: DownloadStatus.queued),
        ],
      );

      final removed = controller.clearFinishedItems();
      expect(removed, 2);
      expect(controller.itemCount, 1);
      expect(controller.items.first.id, '3');
    });

    test('advanceFakeProgress increments downloading progress', () {
      final controller = DownloadQueueController(
        initialItems: [
          _item(
            id: '1',
            title: 'Run',
            status: DownloadStatus.downloading,
            progress: 0.2,
          ),
        ],
      );

      final changed = controller.advanceFakeProgress(step: 0.1);
      expect(changed, 1);
      expect(controller.items.first.progress, closeTo(0.3, 0.0001));
      expect(controller.items.first.status, DownloadStatus.downloading);
    });

    test('advanceFakeProgress marks item as completed at 1', () {
      final controller = DownloadQueueController(
        initialItems: [
          _item(
            id: '1',
            title: 'Run',
            status: DownloadStatus.downloading,
            progress: 0.95,
          ),
        ],
      );

      final changed = controller.advanceFakeProgress(step: 0.1);
      expect(changed, 1);
      expect(controller.items.first.progress, 1);
      expect(controller.items.first.status, DownloadStatus.completed);
    });

    test('hasRunningItems reflects downloading items', () {
      final controller = DownloadQueueController(
        initialItems: [
          _item(id: '1', title: 'Idle', status: DownloadStatus.queued),
          _item(id: '2', title: 'Run', status: DownloadStatus.downloading),
        ],
      );

      expect(controller.hasRunningItems, isTrue);
      controller.pauseItem('2');
      expect(controller.hasRunningItems, isFalse);
    });

    test('addMockAuthorizedLink preserves transferType', () {
      final controller = DownloadQueueController();

      final created = controller.addMockAuthorizedLink(
        sourceUrl: 'https://example.com/video',
        transferType: DownloadTransferType.audio,
        formatLabel: 'MP3',
        qualityLabel: '1080p',
        outputFolderLabel: 'Downloads',
      );

      expect(controller.itemCount, 1);
      expect(controller.items.first, same(created));
      expect(created.transferType, DownloadTransferType.audio);
      expect(created.status, DownloadStatus.queued);
      expect(created.progress, 0);
      expect(created.sourceUrl, 'https://example.com/video');
      expect(created.formatLabel, 'MP3');
      expect(created.qualityLabel, '1080p');
      expect(created.sourceLabel, contains('Downloads'));
      expect(created.title, startsWith('Novo link autorizado #'));
    });

    test('addMockAuthorizedLink can create item with analyzing status', () {
      final controller = DownloadQueueController();

      final created = controller.addMockAuthorizedLink(
        status: DownloadStatus.analyzing,
      );

      expect(created.status, DownloadStatus.analyzing);
      expect(controller.items.first.status, DownloadStatus.analyzing);
    });

    test('markItemReadyAfterMockAnalysis preenche availableFormats', () {
      final controller = DownloadQueueController();
      final created = controller.addMockAuthorizedLink(
        status: DownloadStatus.analyzing,
        outputFolderLabel: 'Downloads',
        sourceUrl: 'https://example.com/video',
      );

      final updated = controller.markItemReadyAfterMockAnalysis(created.id);

      expect(updated, isNotNull);
      expect(updated!.status, DownloadStatus.ready);
      expect(updated.progress, 0);
      expect(updated.title, 'Link autorizado analisado');
      expect(updated.durationLabel, '03:21');
      expect(updated.sourceLabel, contains('Análise mockada concluída'));
      expect(updated.sourceLabel, contains('Downloads'));
      expect(updated.availableFormats, hasLength(4));
    });

    test(
      'markItemReadyAfterMockAnalysis define selectedFormatId recomendado',
      () {
        final controller = DownloadQueueController();
        final created = controller.addMockAuthorizedLink(
          status: DownloadStatus.analyzing,
        );

        final updated = controller.markItemReadyAfterMockAnalysis(created.id);

        expect(updated, isNotNull);
        expect(updated!.selectedFormatId, 'video-mp4-1080p');
        expect(
          updated.availableFormats
              .firstWhere((f) => f.id == 'video-mp4-1080p')
              .isRecommended,
          isTrue,
        );
      },
    );

    test(
      'markItemReadyAfterMockAnalysis returns null if item is not analyzing',
      () {
        final controller = DownloadQueueController();
        final created = controller.addMockAuthorizedLink(
          status: DownloadStatus.queued,
        );

        final updated = controller.markItemReadyAfterMockAnalysis(created.id);

        expect(updated, isNull);
      },
    );

    test('markItemReadyAfterMockAnalysis returns null for unknown id', () {
      final controller = DownloadQueueController();

      final updated = controller.markItemReadyAfterMockAnalysis('missing-id');

      expect(updated, isNull);
    });

    test(
      'markItemReadyAfterRealAnalysis com URL inválida falha de forma controlada',
      () async {
        final controller = DownloadQueueController();
        final created = controller.addMockAuthorizedLink(
          status: DownloadStatus.analyzing,
          sourceUrl: 'nota-interna',
        );

        final updated = await controller.markItemReadyAfterRealAnalysis(
          id: created.id,
          settings: const EngineSettings(),
        );

        expect(updated, isNotNull);
        expect(updated!.status, DownloadStatus.failed);
        expect(updated.sourceLabel, 'Falha na análise real');
      },
    );

    test(
      'selectFormatForItem altera selectedFormatId quando formato existe',
      () {
        final controller = DownloadQueueController();
        final created = controller.addMockAuthorizedLink(
          status: DownloadStatus.analyzing,
        );
        controller.markItemReadyAfterMockAnalysis(created.id);

        final updated = controller.selectFormatForItem(created.id, 'audio-m4a');

        expect(updated, isNotNull);
        expect(updated!.selectedFormatId, 'audio-m4a');
      },
    );

    test('selectFormatForItem retorna null quando item não existe', () {
      final controller = DownloadQueueController();

      final updated = controller.selectFormatForItem('missing-id', 'audio-m4a');

      expect(updated, isNull);
    });

    test('selectFormatForItem retorna null quando formato não existe', () {
      final controller = DownloadQueueController();
      final created = controller.addMockAuthorizedLink(
        status: DownloadStatus.analyzing,
      );
      controller.markItemReadyAfterMockAnalysis(created.id);

      final updated = controller.selectFormatForItem(
        created.id,
        'missing-format',
      );

      expect(updated, isNull);
    });

    test('startItem ainda funciona depois de selecionar formato', () {
      final controller = DownloadQueueController();
      final created = controller.addMockAuthorizedLink(
        status: DownloadStatus.analyzing,
      );
      controller.markItemReadyAfterMockAnalysis(created.id);
      controller.selectFormatForItem(created.id, 'audio-m4a');

      final started = controller.startItem(created.id);

      expect(started, isNotNull);
      expect(started!.status, DownloadStatus.downloading);
    });

    test('attachMockCommandPreview retorna null para item inexistente', () {
      final controller = DownloadQueueController();
      final updated = controller.attachMockCommandPreview(
        itemId: 'missing-id',
        settings: const EngineSettings(),
      );
      expect(updated, isNull);
    });

    test(
      'attachMockCommandPreview retorna null se item não tiver formato selecionado',
      () {
        final controller = DownloadQueueController();
        final created = controller.addMockAuthorizedLink(
          status: DownloadStatus.ready,
        );

        final updated = controller.attachMockCommandPreview(
          itemId: created.id,
          settings: const EngineSettings(),
        );

        expect(updated, isNull);
      },
    );

    test(
      'attachMockCommandPreview salva commandPreviewLabel para item ready com formato selecionado',
      () {
        final controller = DownloadQueueController();
        final created = controller.addMockAuthorizedLink(
          status: DownloadStatus.analyzing,
          sourceUrl: 'https://example.com/video',
        );
        controller.markItemReadyAfterMockAnalysis(created.id);

        final updated = controller.attachMockCommandPreview(
          itemId: created.id,
          settings: const EngineSettings(),
          outputFolderLabel: 'Vídeos',
        );

        expect(updated, isNotNull);
        expect(updated!.commandPreviewLabel, isNotNull);
        expect(updated.commandPreviewLabel, contains('yt-dlp'));
      },
    );

    test('trocar formato e anexar preview atualiza commandPreviewLabel', () {
      final controller = DownloadQueueController();
      final created = controller.addMockAuthorizedLink(
        status: DownloadStatus.analyzing,
        sourceUrl: 'https://example.com/video',
      );
      controller.markItemReadyAfterMockAnalysis(created.id);
      controller.attachMockCommandPreview(
        itemId: created.id,
        settings: const EngineSettings(),
      );
      final before = controller.items
          .firstWhere((item) => item.id == created.id)
          .commandPreviewLabel;

      controller.selectFormatForItem(created.id, 'audio-m4a');
      final after = controller.attachMockCommandPreview(
        itemId: created.id,
        settings: const EngineSettings(),
      );

      expect(after, isNotNull);
      expect(after!.commandPreviewLabel, isNotNull);
      expect(after.commandPreviewLabel, contains('--extract-audio'));
      expect(after.commandPreviewLabel, isNot(equals(before)));
    });

    test('item can start downloading after mock analysis is completed', () {
      final controller = DownloadQueueController();
      final created = controller.addMockAuthorizedLink(
        status: DownloadStatus.analyzing,
      );

      controller.markItemReadyAfterMockAnalysis(created.id);
      final started = controller.startItem(created.id);

      expect(started, isNotNull);
      expect(started!.status, DownloadStatus.downloading);
    });

    test('resetForTesting replaces list and keeps immutability', () {
      final controller = DownloadQueueController();
      controller.addMockAuthorizedLink();

      final replacement = [_item(id: 'new-1', title: 'New 1')];
      controller.resetForTesting(replacement);

      expect(controller.itemCount, 1);
      expect(controller.items.first.id, 'new-1');
      expect(
        () => controller.items.removeAt(0),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
