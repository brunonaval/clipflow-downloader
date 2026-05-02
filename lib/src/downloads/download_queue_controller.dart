import 'download_item.dart';

class DownloadQueueController {
  DownloadQueueController({List<DownloadItem>? initialItems})
    : _items = List.of(initialItems ?? <DownloadItem>[]),
      _nextMockItemNumber = (initialItems?.length ?? 0) + 1;

  List<DownloadItem> _items;
  int _nextMockItemNumber;

  List<DownloadItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.length;

  String get itemCountLabel {
    if (itemCount == 0) return '0 itens';
    if (itemCount == 1) return '1 item';
    return '$itemCount itens';
  }

  DownloadItem addMockAuthorizedLink({
    String? sourceUrl,
    String formatLabel = 'MP4',
    String qualityLabel = 'Ótima',
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
      sourceLabel: 'Aguardando análise',
      status: DownloadStatus.queued,
      progress: 0,
    );

    _items.insert(0, item);
    return item;
  }

  void resetForTesting(List<DownloadItem> items) {
    _items = List.of(items);
    _nextMockItemNumber = _items.length + 1;
  }
}
