import 'download_item.dart';
import 'download_options.dart';
import 'download_queue_filter.dart';

class DownloadQueueController {
  DownloadQueueController({List<DownloadItem>? initialItems})
    : _items = List.of(initialItems ?? <DownloadItem>[]),
      _nextMockItemNumber = (initialItems?.length ?? 0) + 1;

  List<DownloadItem> _items;
  int _nextMockItemNumber;

  List<DownloadItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.length;

  bool get hasRunningItems =>
      _items.any((item) => item.status == DownloadStatus.downloading);

  String get itemCountLabel {
    if (itemCount == 0) return '0 itens';
    if (itemCount == 1) return '1 item';
    return '$itemCount itens';
  }

  List<DownloadItem> filteredItems({
    required DownloadQueueFilter filter,
    String searchQuery = '',
  }) {
    final byFilter = switch (filter) {
      DownloadQueueFilter.all => _items,
      DownloadQueueFilter.video =>
        _items
            .where((item) => item.transferType == DownloadTransferType.video)
            .toList(),
      DownloadQueueFilter.audio =>
        _items
            .where((item) => item.transferType == DownloadTransferType.audio)
            .toList(),
      DownloadQueueFilter.playlists ||
      DownloadQueueFilter.channels ||
      DownloadQueueFilter.subscriptions ||
      DownloadQueueFilter.ai => <DownloadItem>[],
    };

    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return List.unmodifiable(byFilter);

    final filtered = byFilter.where((item) {
      final sourceUrl = item.sourceUrl ?? '';
      final haystack =
          '${item.title}\n${item.metadataLabel}\n${item.sourceLabel}\n$sourceUrl'
              .toLowerCase();
      return haystack.contains(query);
    }).toList();

    return List.unmodifiable(filtered);
  }

  String filteredItemCountLabel({
    required DownloadQueueFilter filter,
    String searchQuery = '',
  }) {
    final count = filteredItems(
      filter: filter,
      searchQuery: searchQuery,
    ).length;
    if (count == 0) return '0 itens';
    if (count == 1) return '1 item';
    return '$count itens';
  }

  DownloadItem addMockAuthorizedLink({
    String? sourceUrl,
    DownloadTransferType transferType = DownloadTransferType.video,
    String formatLabel = 'MP4',
    String qualityLabel = 'Ótima',
    String outputFolderLabel = 'Vídeos',
    DownloadStatus status = DownloadStatus.queued,
  }) {
    final currentNumber = _nextMockItemNumber;
    _nextMockItemNumber += 1;

    final item = DownloadItem(
      id: 'mock-local-$currentNumber',
      title: 'Novo link autorizado #$currentNumber',
      sourceUrl: sourceUrl,
      durationLabel: '--:--',
      sizeLabel: 'Aguardando',
      formatLabel: formatLabel,
      qualityLabel: qualityLabel,
      fpsLabel: '--fps',
      sourceLabel: 'Aguardando análise · $outputFolderLabel',
      transferType: transferType,
      status: status,
      progress: 0,
    );

    _items.insert(0, item);
    return item;
  }

  DownloadItem? startItem(String id) {
    final index = _indexOf(id);
    if (index < 0) return null;

    final item = _items[index];
    final canStart =
        item.status == DownloadStatus.queued ||
        item.status == DownloadStatus.ready ||
        item.status == DownloadStatus.paused ||
        item.status == DownloadStatus.failed ||
        item.status == DownloadStatus.canceled;

    if (!canStart) return null;

    final updated = item.copyWith(
      status: DownloadStatus.downloading,
      progress: item.progress >= 1 ? 0 : item.progress,
    );
    return _replaceAt(index, updated);
  }

  DownloadItem? markItemReadyAfterMockAnalysis(String id) {
    final index = _indexOf(id);
    if (index < 0) return null;

    final item = _items[index];
    if (item.status != DownloadStatus.analyzing) return null;

    final outputFolder = _extractOutputFolderFromSource(item.sourceLabel);
    final updated = item.copyWith(
      status: DownloadStatus.ready,
      progress: 0,
      sourceLabel: 'Análise mockada concluída · $outputFolder',
    );
    return _replaceAt(index, updated);
  }

  DownloadItem? pauseItem(String id) {
    final index = _indexOf(id);
    if (index < 0) return null;

    final item = _items[index];
    if (item.status != DownloadStatus.downloading) return null;

    final updated = item.copyWith(status: DownloadStatus.paused);
    return _replaceAt(index, updated);
  }

  DownloadItem? cancelItem(String id) {
    final index = _indexOf(id);
    if (index < 0) return null;

    final item = _items[index];
    if (item.status == DownloadStatus.completed) return null;

    final updated = item.copyWith(status: DownloadStatus.canceled);
    return _replaceAt(index, updated);
  }

  DownloadItem? removeItem(String id) {
    final index = _indexOf(id);
    if (index < 0) return null;
    return _items.removeAt(index);
  }

  int clearFinishedItems() {
    final before = _items.length;
    _items.removeWhere(
      (item) =>
          item.status == DownloadStatus.completed ||
          item.status == DownloadStatus.canceled,
    );
    return before - _items.length;
  }

  int advanceFakeProgress({double step = 0.08}) {
    var changed = 0;
    final safeStep = step < 0 ? 0.0 : step;

    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.status != DownloadStatus.downloading) continue;

      final nextProgress = item.progress + safeStep;
      if (nextProgress >= 1) {
        _items[i] = item.copyWith(
          status: DownloadStatus.completed,
          progress: 1,
        );
      } else {
        _items[i] = item.copyWith(
          status: DownloadStatus.downloading,
          progress: nextProgress,
        );
      }
      changed += 1;
    }

    return changed;
  }

  void resetForTesting(List<DownloadItem> items) {
    _items = List.of(items);
    _nextMockItemNumber = _items.length + 1;
  }

  int _indexOf(String id) => _items.indexWhere((item) => item.id == id);

  String _extractOutputFolderFromSource(String sourceLabel) {
    const separator = '·';
    final index = sourceLabel.lastIndexOf(separator);
    if (index < 0 || index == sourceLabel.length - 1) return 'Vídeos';
    return sourceLabel.substring(index + 1).trim();
  }

  DownloadItem _replaceAt(int index, DownloadItem updated) {
    _items[index] = updated;
    return updated;
  }
}
