import '../engine/mock_engine_service.dart';
import '../engine/internal_engine_service.dart';
import '../engine/youtube/youtube_extractor.dart';
import '../engine/yt_dlp/yt_dlp_analysis_result.dart';
import 'download_item.dart';
import 'download_format_option.dart';
import 'download_options.dart';
import 'download_queue_filter.dart';

class DownloadQueueController {
  DownloadQueueController({
    List<DownloadItem>? initialItems,
    MockEngineService engineService = const MockEngineService(),
  }) : _engineService = engineService,
       _items = List.of(initialItems ?? <DownloadItem>[]),
       _nextMockItemNumber = (initialItems?.length ?? 0) + 1;

  final MockEngineService _engineService;
  final InternalEngineService _internalEngineService =
      const InternalEngineService();
  final YouTubeExtractor _youtubeExtractor = const YouTubeExtractor();
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
    return markItemDownloading(id);
  }

  DownloadItem? markItemDownloading(String id) {
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
    final result = _engineService.analyzeMockUrl(
      sourceUrl: item.sourceUrl,
      outputFolderLabel: outputFolder,
    );

    final updated = item.copyWith(
      status: DownloadStatus.ready,
      progress: 0,
      title: result.title,
      durationLabel: result.durationLabel,
      sourceLabel: result.sourceLabel,
      availableFormats: result.formats,
      selectedFormatId: result.recommendedFormatId,
    );
    return _replaceAt(index, updated);
  }

  DownloadItem? markItemReadyAfterInternalAnalysis({
    required String id,
    String outputFolderLabel = 'Vídeos',
  }) {
    final index = _indexOf(id);
    if (index < 0) return null;

    final item = _items[index];
    if (item.status != DownloadStatus.analyzing) return null;

    final result = _internalEngineService.analyzeUrl(
      rawUrl: item.sourceUrl ?? '',
      outputFolderLabel: outputFolderLabel,
    );

    if (result.formats.isEmpty) {
      final failed = item.copyWith(
        status: DownloadStatus.failed,
        sourceLabel: result.sourceLabel,
        progress: 0,
        directDownloadUrl: null,
        outputFileName: null,
      );
      return _replaceAt(index, failed);
    }

    String? directDownloadUrl;
    String? outputFileName;
    if (result.canDownloadDirectly && result.directDownloadUri != null) {
      directDownloadUrl = result.directDownloadUri.toString();
      outputFileName = _safeOutputFileNameFromUri(result.directDownloadUri!);
    }

    final updated = item.copyWith(
      status: DownloadStatus.ready,
      progress: 0,
      title: result.title,
      durationLabel: result.durationLabel,
      sourceLabel: result.sourceLabel,
      availableFormats: result.formats,
      selectedFormatId: result.recommendedFormatId,
      directDownloadUrl: directDownloadUrl,
      outputFileName: outputFileName,
      isYouTubeSource: _youtubeExtractor.isYouTubeUrl(item.sourceUrl ?? ''),
    );
    return _replaceAt(index, updated);
  }

  Future<DownloadItem?> markItemReadyAfterYouTubeMetadataAnalysis({
    required String id,
    String outputFolderLabel = 'Vídeos',
  }) async {
    final index = _indexOf(id);
    if (index < 0) return null;

    final item = _items[index];
    if (item.status != DownloadStatus.analyzing) return null;

    final result = await _youtubeExtractor.analyzeUrlMetadata(
      rawUrl: item.sourceUrl ?? '',
      outputFolderLabel: outputFolderLabel,
    );
    if (result == null) return null;

    if (result.formats.isEmpty) {
      final failed = item.copyWith(
        status: DownloadStatus.failed,
        title: result.title,
        durationLabel: result.durationLabel,
        sourceLabel: result.sourceLabel,
        progress: 0,
        directDownloadUrl: null,
        outputFileName: null,
      );
      return _replaceAt(index, failed);
    }

    final updated = item.copyWith(
      status: DownloadStatus.ready,
      progress: 0,
      title: result.title,
      durationLabel: result.durationLabel,
      sourceLabel: result.sourceLabel,
      availableFormats: result.formats,
      selectedFormatId: result.recommendedFormatId,
      directDownloadUrl: null,
      outputFileName: null,
      isYouTubeSource: true,
    );
    return _replaceAt(index, updated);
  }

  DownloadItem? applyYtDlpAnalysis({
    required String id,
    required YtDlpAnalysisResult result,
  }) {
    final index = _indexOf(id);
    if (index < 0) return null;

    final item = _items[index];
    final updated = item.copyWith(
      status: DownloadStatus.ready,
      progress: 0,
      title: result.title,
      durationLabel: result.durationLabel,
      sourceLabel: 'Análise yt-dlp concluída',
      availableFormats: result.formats,
      selectedFormatId: result.recommendedFormatId,
      isYouTubeSource: true,
      directDownloadUrl: null,
      outputFileName: null,
    );
    final preview = _buildYtDlpPreview(
      selectedFormatId: updated.selectedFormatId,
      formats: updated.availableFormats,
    );
    return _replaceAt(index, updated.copyWith(commandPreviewLabel: preview));
  }

  DownloadItem? updateItemProgress(String id, double progress) {
    final index = _indexOf(id);
    if (index < 0) return null;
    final item = _items[index];
    final updated = item.copyWith(progress: progress.clamp(0.0, 1.0));
    return _replaceAt(index, updated);
  }

  DownloadItem? markItemCompleted(String id) {
    final index = _indexOf(id);
    if (index < 0) return null;
    final item = _items[index];
    final updated = item.copyWith(
      status: DownloadStatus.completed,
      progress: 1,
    );
    return _replaceAt(index, updated);
  }

  DownloadItem? markItemCompletedWithMessage(String id, String message) {
    final index = _indexOf(id);
    if (index < 0) return null;
    final item = _items[index];
    final updated = item.copyWith(
      status: DownloadStatus.completed,
      progress: 1,
      sourceLabel: message,
    );
    return _replaceAt(index, updated);
  }

  DownloadItem? markItemFailed(String id, String message) {
    final index = _indexOf(id);
    if (index < 0) return null;
    final item = _items[index];
    final updated = item.copyWith(
      status: DownloadStatus.failed,
      sourceLabel: message,
    );
    return _replaceAt(index, updated);
  }

  DownloadItem? selectFormatForItem(String itemId, String formatId) {
    final index = _indexOf(itemId);
    if (index < 0) return null;

    final item = _items[index];
    final exists = item.availableFormats.any((f) => f.id == formatId);
    if (!exists) return null;

    String? preview = item.commandPreviewLabel;
    if (item.isYouTubeSource) {
      preview = _buildYtDlpPreview(
        selectedFormatId: formatId,
        formats: item.availableFormats,
      );
    }
    final updated = item.copyWith(
      selectedFormatId: formatId,
      commandPreviewLabel: preview,
    );
    return _replaceAt(index, updated);
  }

  DownloadFormatOption? selectedFormatForItem(String itemId) {
    final index = _indexOf(itemId);
    if (index < 0) return null;

    final item = _items[index];
    if (item.availableFormats.isEmpty) return null;

    final selectedId = item.selectedFormatId;
    if (selectedId == null || selectedId.isEmpty) {
      return item.availableFormats.first;
    }

    for (final format in item.availableFormats) {
      if (format.id == selectedId) return format;
    }

    return null;
  }

  DownloadItem? attachMockCommandPreview({
    required String itemId,
    String outputFolderLabel = 'Vídeos',
  }) {
    final index = _indexOf(itemId);
    if (index < 0) return null;

    final item = _items[index];
    if (item.availableFormats.isEmpty || item.selectedFormatId == null) {
      return null;
    }

    final selected = item.availableFormats.where((f) {
      return f.id == item.selectedFormatId;
    }).toList();
    if (selected.isEmpty) return null;
    if (item.isYouTubeSource) {
      final preview = _buildYtDlpPreview(
        selectedFormatId: item.selectedFormatId,
        formats: item.availableFormats,
      );
      final updated = item.copyWith(commandPreviewLabel: preview);
      return _replaceAt(index, updated);
    }

    final sourceUrl = (item.sourceUrl?.trim().isNotEmpty ?? false)
        ? item.sourceUrl!.trim()
        : 'https://mock.local/authorized-link';

    final plan = _engineService.buildMockDownloadPlan(
      sourceUrl: sourceUrl,
      selectedFormat: selected.first,
      outputFolderLabel: outputFolderLabel,
    );

    final updated = item.copyWith(commandPreviewLabel: plan.preview);
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
      if (item.directDownloadUrl != null) continue;

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

  String _safeOutputFileNameFromUri(Uri uri) {
    final lastSegment = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : '';
    final decoded = Uri.decodeComponent(lastSegment).trim();
    final baseName = decoded.isNotEmpty ? decoded : 'clipflow-download.bin';
    final cleaned = baseName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    if (cleaned.isEmpty) return 'clipflow-download.bin';
    if (cleaned.length <= 120) return cleaned;
    return cleaned.substring(0, 120);
  }

  DownloadItem _replaceAt(int index, DownloadItem updated) {
    _items[index] = updated;
    return updated;
  }

  String? _buildYtDlpPreview({
    required String? selectedFormatId,
    required List<DownloadFormatOption> formats,
  }) {
    if (selectedFormatId == null || selectedFormatId.isEmpty) return null;
    final selected = formats.where((f) => f.id == selectedFormatId).toList();
    if (selected.isEmpty) return null;
    final format = selected.first;
    if (format.detailsLabel.contains('[video-only]')) {
      return 'yt-dlp -f ${format.id}+bestaudio/best · merge MP4 com FFmpeg';
    }
    return 'yt-dlp -f ${format.id}';
  }
}
