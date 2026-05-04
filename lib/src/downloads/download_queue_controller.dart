import '../engine/mock_engine_service.dart';
import '../engine/internal_engine_service.dart';
import '../engine/youtube/youtube_extractor.dart';
import '../engine/yt_dlp/yt_dlp_analysis_result.dart';
import '../engine/yt_dlp/yt_dlp_playlist_result.dart';
import 'download_item.dart';
import 'download_format_option.dart';
import 'download_format_selector.dart';
import 'download_options.dart';
import 'download_preset.dart';
import 'download_queue_filter.dart';
import 'download_sort_option.dart';

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
  final DownloadFormatSelector _formatSelector = const DownloadFormatSelector();
  List<DownloadItem> _items;
  int _nextMockItemNumber;

  List<DownloadItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.length;

  bool get hasRunningItems =>
      _items.any((item) => item.status == DownloadStatus.downloading);

  int get activeTransferCount => _items
      .where(
        (item) =>
            item.status == DownloadStatus.downloading ||
            item.status == DownloadStatus.analyzing,
      )
      .length;

  List<DownloadItem> get startableItems => _items
      .where(
        (item) =>
            item.status == DownloadStatus.queued ||
            item.status == DownloadStatus.ready,
      )
      .toList(growable: false);

  bool get hasStartableItems => startableItems.isNotEmpty;

  DownloadItem? nextStartableItem() {
    final list = startableItems;
    if (list.isEmpty) return null;
    return list.first;
  }

  String get itemCountLabel {
    if (itemCount == 0) return '0 itens';
    if (itemCount == 1) return '1 item';
    return '$itemCount itens';
  }

  List<DownloadItem> filteredItems({
    required DownloadQueueFilter filter,
    String searchQuery = '',
    DownloadSortOption sortOption = DownloadSortOption.newestFirst,
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
    final filtered = query.isEmpty
        ? List<DownloadItem>.of(byFilter)
        : byFilter.where((item) {
            final sourceUrl = item.sourceUrl ?? '';
            final author = item.authorLabel ?? '';
            final selectedSummary = item.selectedFormatSummary ?? '';
            final outputSummary = item.outputSummaryLabel ?? '';
            final haystack =
                '${item.title}\n$author\n$selectedSummary\n$outputSummary\n${item.metadataLabel}\n${item.sourceLabel}\n$sourceUrl\n${item.formatLabel}\n${item.qualityLabel}'
                    .toLowerCase();
            return haystack.contains(query);
          }).toList();

    _sortItems(filtered, sortOption);
    return List.unmodifiable(filtered);
  }

  String filteredItemCountLabel({
    required DownloadQueueFilter filter,
    String searchQuery = '',
    DownloadSortOption sortOption = DownloadSortOption.newestFirst,
  }) {
    final count = filteredItems(
      filter: filter,
      searchQuery: searchQuery,
      sortOption: sortOption,
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
      addedAt: DateTime.now(),
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

  DownloadItem? markItemAnalyzing(String id, String message) {
    final index = _indexOf(id);
    if (index < 0) return null;
    final item = _items[index];
    final canAnalyze =
        item.status == DownloadStatus.queued ||
        item.status == DownloadStatus.ready ||
        item.status == DownloadStatus.failed ||
        item.status == DownloadStatus.canceled;
    if (!canAnalyze) return null;

    final updated = item.copyWith(
      status: DownloadStatus.analyzing,
      sourceLabel: message,
      progress: 0,
    );
    return _replaceAt(index, updated);
  }

  List<DownloadItem> addPlaylistEntries({
    required List<YtDlpPlaylistEntry> entries,
    required DownloadTransferType transferType,
    required String formatLabel,
    required String qualityLabel,
    required String outputFolderLabel,
  }) {
    final created = <DownloadItem>[];
    for (final entry in entries) {
      final currentNumber = _nextMockItemNumber;
      _nextMockItemNumber += 1;
      final item = DownloadItem(
        id: 'playlist-$currentNumber-${entry.id}',
        title: entry.title,
        sourceUrl: entry.url,
        durationLabel: entry.durationLabel ?? '--:--',
        sizeLabel: 'Aguardando',
        formatLabel: formatLabel,
        qualityLabel: qualityLabel,
        fpsLabel: '--fps',
        sourceLabel: 'Na fila · clique em play para analisar',
        addedAt: DateTime.now(),
        transferType: transferType,
        status: DownloadStatus.queued,
        availableFormats: const [],
        selectedFormatId: null,
        thumbnailUrl: entry.thumbnailUrl,
        authorLabel: entry.authorLabel,
        isYouTubeSource: true,
      );
      _items.add(item);
      created.add(item);
    }
    return created;
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
    DownloadPreset? preset,
  }) {
    final index = _indexOf(id);
    if (index < 0) return null;

    final item = _items[index];
    final selectedByPreset = preset == null
        ? null
        : _formatSelector.selectRecommendedFormatId(
            formats: result.formats,
            preset: preset,
          );

    final updated = item.copyWith(
      status: DownloadStatus.ready,
      progress: 0,
      title: result.title,
      durationLabel: result.durationLabel,
      sourceLabel: 'Análise yt-dlp concluída',
      availableFormats: result.formats,
      selectedFormatId: selectedByPreset ?? result.recommendedFormatId,
      thumbnailUrl: result.thumbnailUrl,
      authorLabel: result.authorLabel,
      selectedFormatSummary: _formatSummaryForSelected(
        selectedFormatId: selectedByPreset ?? result.recommendedFormatId,
        formats: result.formats,
      ),
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

  DownloadItem? markItemCompletedWithOutput({
    required String id,
    required String message,
    String? outputPath,
    required String outputDirectoryPath,
  }) {
    final index = _indexOf(id);
    if (index < 0) return null;
    final item = _items[index];

    final updated = item.copyWith(
      status: DownloadStatus.completed,
      progress: 1,
      sourceLabel: message,
      outputPath: outputPath,
      outputDirectoryPath: outputDirectoryPath,
      outputSummaryLabel: _outputSummaryLabel(outputPath),
    );
    return _replaceAt(index, updated);
  }

  DownloadItem? markItemCompletedWithDirectory({
    required String id,
    required String message,
    required String outputDirectoryPath,
  }) {
    final index = _indexOf(id);
    if (index < 0) return null;
    final item = _items[index];

    final updated = item.copyWith(
      status: DownloadStatus.completed,
      progress: 1,
      sourceLabel: message,
      outputPath: null,
      outputDirectoryPath: outputDirectoryPath,
    );
    return _replaceAt(index, updated);
  }

  DownloadItem? markItemMerging(String id) {
    final index = _indexOf(id);
    if (index < 0) return null;
    final item = _items[index];
    if (item.status != DownloadStatus.downloading) return null;
    final updated = item.copyWith(sourceLabel: 'Mesclando com FFmpeg');
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
      selectedFormatSummary: _formatSummaryForSelected(
        selectedFormatId: formatId,
        formats: item.availableFormats,
      ),
      commandPreviewLabel: preview,
    );
    return _replaceAt(index, updated);
  }

  DownloadItem? applyPresetSelectionForItem(
    String itemId,
    DownloadPreset preset,
  ) {
    final index = _indexOf(itemId);
    if (index < 0) return null;

    final item = _items[index];
    if (item.status != DownloadStatus.ready || item.availableFormats.isEmpty) {
      return null;
    }

    final selectedId = _formatSelector.selectRecommendedFormatId(
      formats: item.availableFormats,
      preset: preset,
    );
    if (selectedId == null || selectedId == item.selectedFormatId) {
      return item;
    }

    final updated = item.copyWith(
      selectedFormatId: selectedId,
      selectedFormatSummary: _formatSummaryForSelected(
        selectedFormatId: selectedId,
        formats: item.availableFormats,
      ),
    );
    final preview = item.isYouTubeSource
        ? _buildYtDlpPreview(
            selectedFormatId: updated.selectedFormatId,
            formats: updated.availableFormats,
          )
        : updated.commandPreviewLabel;
    return _replaceAt(index, updated.copyWith(commandPreviewLabel: preview));
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

  int clearFailedItems() {
    final before = _items.length;
    _items.removeWhere((item) => item.status == DownloadStatus.failed);
    return before - _items.length;
  }

  int clearInactiveItems() {
    final before = _items.length;
    _items.removeWhere((item) {
      return item.status == DownloadStatus.queued ||
          item.status == DownloadStatus.ready ||
          item.status == DownloadStatus.completed ||
          item.status == DownloadStatus.failed ||
          item.status == DownloadStatus.canceled;
    });
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

  void _sortItems(List<DownloadItem> items, DownloadSortOption sortOption) {
    int compare(DownloadItem a, DownloadItem b) {
      final result = switch (sortOption.field) {
        DownloadSortField.added => _compareAddedAt(a, b),
        DownloadSortField.title => a.title.toLowerCase().compareTo(
          b.title.toLowerCase(),
        ),
        DownloadSortField.status => a.status.index.compareTo(b.status.index),
        DownloadSortField.type => a.transferType.index.compareTo(
          b.transferType.index,
        ),
        DownloadSortField.author =>
          (a.authorLabel ?? '').toLowerCase().compareTo(
            (b.authorLabel ?? '').toLowerCase(),
          ),
      };
      if (result != 0) return result;
      return a.id.compareTo(b.id);
    }

    items.sort((a, b) {
      final base = compare(a, b);
      if (sortOption.direction == DownloadSortDirection.ascending) return base;
      return -base;
    });
  }

  int _compareAddedAt(DownloadItem a, DownloadItem b) {
    final aAt = a.addedAt;
    final bAt = b.addedAt;
    if (aAt == null && bAt == null) return 0;
    if (aAt == null) return -1;
    if (bAt == null) return 1;
    return aAt.compareTo(bAt);
  }

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
      final isMp4 = format.formatLabel.trim().toUpperCase() == 'MP4';
      if (isMp4) {
        return 'yt-dlp -f ${format.id} + áudio M4A/AAC · merge MP4 com FFmpeg';
      }
      return 'yt-dlp -f ${format.id}+bestaudio/best · merge com FFmpeg';
    }
    return 'yt-dlp -f ${format.id}';
  }

  String? _formatSummaryForSelected({
    required String? selectedFormatId,
    required List<DownloadFormatOption> formats,
  }) {
    if (selectedFormatId == null || selectedFormatId.isEmpty) return null;
    final selected = formats.where((f) => f.id == selectedFormatId).toList();
    if (selected.isEmpty) return null;
    final format = selected.first;
    final parts = <String>[
      format.formatLabel.toUpperCase(),
      format.qualityLabel,
    ];
    final detailsLower = format.detailsLabel.toLowerCase();
    if (detailsLower.contains('[video-only]')) {
      parts.add('video-only');
    } else if (detailsLower.contains('[muxed]')) {
      parts.add('com áudio');
    }
    return parts.where((part) => part.trim().isNotEmpty).join(' · ');
  }

  String _outputSummaryLabel(String? outputPath) {
    final trimmed = outputPath?.trim() ?? '';
    if (trimmed.isEmpty) return 'Arquivo salvo';
    final fileName = trimmed.split(RegExp(r'[\\/]')).last.trim();
    if (fileName.isEmpty) return 'Arquivo salvo';
    return fileName;
  }
}
