import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../downloads/download_item.dart';
import '../downloads/download_format_option.dart';
import '../downloads/download_options.dart';
import '../downloads/download_queue_controller.dart';
import '../downloads/download_queue_filter.dart';
import '../engine/engine_availability_checker.dart';
import '../engine/engine_availability_result.dart';
import '../engine/engine_settings.dart';
import '../engine/engine_settings_dialog.dart';
import 'mock_download_item.dart';

const _kGreen = Color(0xFF2E7D32);
const _kDivider = Color(0xFFE0E0E0);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DownloadQueueFilter _activeFilter = DownloadQueueFilter.all;
  DownloadOptions _downloadOptions = const DownloadOptions();
  EngineSettings _engineSettings = const EngineSettings();
  EngineAvailabilityResult _engineAvailability =
      EngineAvailabilityResult.unknown('yt-dlp');
  bool _isCheckingEngine = false;
  String _searchQuery = '';
  Timer? _fakeProgressTimer;
  Timer? _mockAnalysisTimer;

  late final DownloadQueueController _queueController;

  @override
  void initState() {
    super.initState();
    _queueController = DownloadQueueController(
      initialItems: initialMockDownloadItems,
    );
  }

  @override
  void dispose() {
    _fakeProgressTimer?.cancel();
    _fakeProgressTimer = null;
    _mockAnalysisTimer?.cancel();
    _mockAnalysisTimer = null;
    super.dispose();
  }

  void _ensureFakeProgressTimer() {
    if (_fakeProgressTimer != null) return;
    _fakeProgressTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _tickFakeProgress(),
    );
  }

  void _stopFakeProgressTimerIfIdle() {
    if (_queueController.hasRunningItems) return;
    _fakeProgressTimer?.cancel();
    _fakeProgressTimer = null;
  }

  void _tickFakeProgress() {
    if (!mounted) return;
    final changed = _queueController.advanceFakeProgress(step: 0.08);
    if (changed > 0) {
      setState(() {});
    }
    _stopFakeProgressTimerIfIdle();
  }

  Future<void> _handlePaste() async {
    String? url;
    try {
      final data = await Clipboard.getData(
        'text/plain',
      ).timeout(const Duration(milliseconds: 150), onTimeout: () => null);
      final text = data?.text ?? '';
      if (text.isNotEmpty) {
        url = text;
      }
    } catch (_) {
      // Clipboard may be unavailable; proceed without URL.
    }

    if (!mounted) return;

    final addedItem = _queueController.addMockAuthorizedLink(
      sourceUrl: url,
      transferType: _downloadOptions.transferType,
      formatLabel: _downloadOptions.formatLabel,
      qualityLabel: _downloadOptions.qualityLabel,
      outputFolderLabel: _downloadOptions.outputFolderLabel,
      status: DownloadStatus.analyzing,
    );

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Análise mockada iniciada'),
        duration: Duration(milliseconds: 1200),
      ),
    );

    _mockAnalysisTimer?.cancel();
    _mockAnalysisTimer = Timer(const Duration(milliseconds: 900), () {
      final updated = _queueController.markItemReadyAfterMockAnalysis(
        addedItem.id,
      );
      if (!mounted || updated == null) return;

      _queueController.attachMockCommandPreview(
        itemId: addedItem.id,
        settings: _engineSettings,
        outputFolderLabel: _downloadOptions.outputFolderLabel,
      );

      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Análise mockada concluída'),
          duration: Duration(milliseconds: 1200),
        ),
      );
    });
  }

  void _startItem(DownloadItem item) {
    final started = _queueController.startItem(item.id);
    if (started == null) return;

    _ensureFakeProgressTimer();
    setState(() {});
  }

  void _pauseItem(DownloadItem item) {
    final paused = _queueController.pauseItem(item.id);
    if (paused == null) return;

    setState(() {});
    _stopFakeProgressTimerIfIdle();
  }

  void _cancelItem(DownloadItem item) {
    final canceled = _queueController.cancelItem(item.id);
    if (canceled == null) return;

    setState(() {});
    _stopFakeProgressTimerIfIdle();
  }

  void _removeItem(DownloadItem item) {
    final removed = _queueController.removeItem(item.id);
    if (removed == null) return;

    setState(() {});
    _stopFakeProgressTimerIfIdle();
  }

  void _selectFormatForItem(DownloadItem item, String formatId) {
    final updated = _queueController.selectFormatForItem(item.id, formatId);
    if (updated == null) return;
    _queueController.attachMockCommandPreview(
      itemId: item.id,
      settings: _engineSettings,
      outputFolderLabel: _downloadOptions.outputFolderLabel,
    );
    setState(() {});
  }

  void _clearFinishedItems() {
    final removed = _queueController.clearFinishedItems();
    setState(() {});
    _stopFakeProgressTimerIfIdle();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Itens finalizados removidos: $removed'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openEngineSettingsDialog() async {
    final updated = await showDialog<EngineSettings>(
      context: context,
      builder: (_) => EngineSettingsDialog(initialSettings: _engineSettings),
    );

    if (!mounted || updated == null) return;

    setState(() {
      _engineSettings = updated;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuração mockada do motor salva'),
        duration: Duration(seconds: 2),
      ),
    );

    _checkEngineAvailability();
  }

  Future<void> _checkEngineAvailability() async {
    if (_isCheckingEngine) return;

    setState(() {
      _isCheckingEngine = true;
    });

    final result = await const EngineAvailabilityChecker().check(_engineSettings);
    if (!mounted) return;

    setState(() {
      _engineAvailability = result;
      _isCheckingEngine = false;
    });

    final message = result.isAvailable
        ? 'Motor detectado: ${result.versionLabel ?? 'versão detectada'}'
        : 'Motor não disponível: ${result.message}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _queueController.filteredItems(
      filter: _activeFilter,
      searchQuery: _searchQuery,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          const _MenuBar(),
          const Divider(height: 1, thickness: 1, color: _kDivider),
          _Toolbar(
            selectedTransferLabel: _downloadOptions.toolbarTransferLabel,
            selectedQualityLabel: _downloadOptions.toolbarQualityLabel,
            selectedFormatLabel: _downloadOptions.toolbarFormatLabel,
            selectedOutputFolderLabel:
                _downloadOptions.toolbarOutputFolderLabel,
            onTransferChanged: (type) => setState(
              () => _downloadOptions = _downloadOptions.copyWith(
                transferType: type,
              ),
            ),
            onQualityChanged: (value) => setState(
              () => _downloadOptions = _downloadOptions.copyWith(
                qualityLabel: value,
              ),
            ),
            onFormatChanged: (value) => setState(
              () => _downloadOptions = _downloadOptions.copyWith(
                formatLabel: value,
              ),
            ),
            onOutputFolderChanged: (value) => setState(
              () => _downloadOptions = _downloadOptions.copyWith(
                outputFolderLabel: value,
              ),
            ),
            onPaste: _handlePaste,
          ),
          const Divider(height: 1, thickness: 1, color: _kDivider),
          _FilterTabs(
            selectedFilter: _activeFilter,
            itemCountLabel: _queueController.filteredItemCountLabel(
              filter: _activeFilter,
              searchQuery: _searchQuery,
            ),
            onSearchChanged: (value) => setState(() => _searchQuery = value),
            onChanged: (filter) => setState(() => _activeFilter = filter),
          ),
          const Divider(height: 1, thickness: 1, color: _kDivider),
          Expanded(
            child: ColoredBox(
              color: Colors.white,
              child: visibleItems.isEmpty
                  ? const _EmptyFilterState()
                  : ListView.builder(
                      itemCount: visibleItems.length,
                      itemBuilder: (_, i) => _DownloadListItem(
                        item: visibleItems[i],
                        onStart: () => _startItem(visibleItems[i]),
                        onPause: () => _pauseItem(visibleItems[i]),
                        onCancel: () => _cancelItem(visibleItems[i]),
                        onRemove: () => _removeItem(visibleItems[i]),
                        onFormatSelected: (formatId) =>
                            _selectFormatForItem(visibleItems[i], formatId),
                      ),
                    ),
            ),
          ),
          _StatusBar(
            onClearFinished: _clearFinishedItems,
            onConfigureEngine: _openEngineSettingsDialog,
            onCheckEngineAvailability: _checkEngineAvailability,
            engineStatus: _engineSettings.status,
            engineAvailability: _engineAvailability,
            isCheckingEngine: _isCheckingEngine,
          ),
        ],
      ),
    );
  }
}

class _MenuBar extends StatelessWidget {
  const _MenuBar();

  static const _items = ['Arquivo', 'Editar', 'Ver', 'Ferramentas', 'Ajuda'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: const Color(0xFFFAFAFA),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'ClipFlow Downloader',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              indent: 8,
              endIndent: 8,
            ),
            ..._items.map(
              (item) => TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const RoundedRectangleBorder(),
                ),
                child: Text(item, style: const TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final String selectedTransferLabel;
  final String selectedQualityLabel;
  final String selectedFormatLabel;
  final String selectedOutputFolderLabel;
  final ValueChanged<DownloadTransferType> onTransferChanged;
  final ValueChanged<String> onQualityChanged;
  final ValueChanged<String> onFormatChanged;
  final ValueChanged<String> onOutputFolderChanged;
  final VoidCallback onPaste;

  const _Toolbar({
    required this.selectedTransferLabel,
    required this.selectedQualityLabel,
    required this.selectedFormatLabel,
    required this.selectedOutputFolderLabel,
    required this.onTransferChanged,
    required this.onQualityChanged,
    required this.onFormatChanged,
    required this.onOutputFolderChanged,
    required this.onPaste,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: onPaste,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 1,
                    ),
                    child: const Text(
                      'Colar link',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _SelectorButton<DownloadTransferType>(
                    valueLabel: selectedTransferLabel,
                    options: const {
                      DownloadTransferType.video: 'Vídeo',
                      DownloadTransferType.audio: 'Áudio',
                      DownloadTransferType.subtitles: 'Legendas',
                      DownloadTransferType.audioTracks: 'Faixas de áudio',
                    },
                    onChanged: onTransferChanged,
                  ),
                  const SizedBox(width: 8),
                  _SelectorButton<String>(
                    valueLabel: selectedQualityLabel,
                    options: const {
                      'Ótima': 'Ótima',
                      '8K': '8K',
                      '4K': '4K',
                      '1080p': '1080p',
                      '720p': '720p',
                      '480p': '480p',
                      '360p': '360p',
                      '240p': '240p',
                    },
                    onChanged: onQualityChanged,
                  ),
                  const SizedBox(width: 8),
                  _SelectorButton<String>(
                    valueLabel: selectedFormatLabel,
                    options: const {
                      'Automático': 'Automático',
                      'MP4': 'MP4',
                      'MKV': 'MKV',
                      'MP3': 'MP3',
                      'M4A': 'M4A',
                    },
                    onChanged: onFormatChanged,
                  ),
                  const SizedBox(width: 8),
                  _SelectorButton<String>(
                    valueLabel: selectedOutputFolderLabel,
                    options: const {
                      'Vídeos': 'Vídeos',
                      'Downloads': 'Downloads',
                      'Imagens': 'Imagens',
                      'Documentos': 'Documentos',
                      'Navegar...': 'Navegar...',
                    },
                    onChanged: onOutputFolderChanged,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () {},
            tooltip: 'Configurações',
            color: Colors.black54,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _SelectorButton<T> extends StatelessWidget {
  final String valueLabel;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  const _SelectorButton({
    required this.valueLabel,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      onSelected: onChanged,
      itemBuilder: (_) => options.entries
          .map(
            (entry) =>
                PopupMenuItem<T>(value: entry.key, child: Text(entry.value)),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
          color: const Color(0xFFF8F8F8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              valueLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final DownloadQueueFilter selectedFilter;
  final String itemCountLabel;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<DownloadQueueFilter> onChanged;

  const _FilterTabs({
    required this.selectedFilter,
    required this.itemCountLabel,
    required this.onSearchChanged,
    required this.onChanged,
  });

  static const _tabs = DownloadQueueFilter.values;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _tabs.map((tab) {
                  final selected = tab == selectedFilter;
                  return InkWell(
                    onTap: () => onChanged(tab),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selected ? _kGreen : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: selected ? _kGreen : Colors.black87,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            indent: 8,
            endIndent: 8,
          ),
          SizedBox(
            width: 170,
            child: TextField(
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Buscar',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              itemCountLabel,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadListItem extends StatelessWidget {
  final DownloadItem item;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onCancel;
  final VoidCallback onRemove;
  final ValueChanged<String> onFormatSelected;

  const _DownloadListItem({
    required this.item,
    required this.onStart,
    required this.onPause,
    required this.onCancel,
    required this.onRemove,
    required this.onFormatSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDownloading =
        item.status == DownloadStatus.downloading && item.progress > 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 78,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white54,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.metadataLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (item.status == DownloadStatus.ready &&
                        item.availableFormats.isNotEmpty)
                      _FormatSelector(item: item, onSelected: onFormatSelected),
                    if (item.commandPreviewLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Plano: ${item.commandPreviewLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    if (isDownloading)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: LinearProgressIndicator(
                          value: item.progress,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation(_kGreen),
                          minHeight: 3,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _ItemActions(
                item: item,
                onStart: onStart,
                onPause: onPause,
                onCancel: onCancel,
                onRemove: onRemove,
              ),
              const SizedBox(width: 8),
              _StatusBadge(item: item),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
      ],
    );
  }
}

class _FormatSelector extends StatelessWidget {
  final DownloadItem item;
  final ValueChanged<String> onSelected;

  const _FormatSelector({required this.item, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    DownloadFormatOption selected = item.availableFormats.first;
    for (final format in item.availableFormats) {
      if (format.id == item.selectedFormatId) {
        selected = format;
        break;
      }
    }

    final selectedLabel = selected.isRecommended
        ? '${selected.label} (recomendado)'
        : selected.label;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        children: [
          const Text(
            'Formato:',
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
          PopupMenuButton<String>(
            key: Key('formatSelector-${item.id}'),
            onSelected: onSelected,
            itemBuilder: (_) => item.availableFormats
                .map(
                  (format) => PopupMenuItem<String>(
                    key: Key('formatOption-${format.id}'),
                    value: format.id,
                    child: Text(format.displayLabel),
                  ),
                )
                .toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
                color: const Color(0xFFF8F8F8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(selectedLabel, style: const TextStyle(fontSize: 11)),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_drop_down, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemActions extends StatelessWidget {
  final DownloadItem item;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onCancel;
  final VoidCallback onRemove;

  const _ItemActions({
    required this.item,
    required this.onStart,
    required this.onPause,
    required this.onCancel,
    required this.onRemove,
  });

  bool get _canStart =>
      item.status == DownloadStatus.queued ||
      item.status == DownloadStatus.ready ||
      item.status == DownloadStatus.paused ||
      item.status == DownloadStatus.failed ||
      item.status == DownloadStatus.canceled;

  bool get _canPause => item.status == DownloadStatus.downloading;

  bool get _canCancel =>
      item.status == DownloadStatus.queued ||
      item.status == DownloadStatus.ready ||
      item.status == DownloadStatus.downloading ||
      item.status == DownloadStatus.paused ||
      item.status == DownloadStatus.failed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_canStart)
          IconButton(
            icon: const Icon(Icons.play_arrow, size: 18),
            onPressed: onStart,
            tooltip: 'Iniciar',
            visualDensity: VisualDensity.compact,
          ),
        if (_canPause)
          IconButton(
            icon: const Icon(Icons.pause, size: 18),
            onPressed: onPause,
            tooltip: 'Pausar',
            visualDensity: VisualDensity.compact,
          ),
        if (_canCancel)
          IconButton(
            icon: const Icon(Icons.cancel_outlined, size: 18),
            onPressed: onCancel,
            tooltip: 'Cancelar',
            visualDensity: VisualDensity.compact,
          ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          onPressed: onRemove,
          tooltip: 'Remover',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final DownloadItem item;

  const _StatusBadge({required this.item});

  static Color _colorFor(DownloadStatus s) => switch (s) {
    DownloadStatus.completed => const Color(0xFF2E7D32),
    DownloadStatus.failed => Colors.red,
    DownloadStatus.canceled => Colors.grey,
    DownloadStatus.downloading => Colors.blue,
    DownloadStatus.ready => Colors.teal,
    DownloadStatus.paused => Colors.orange,
    _ => Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    return Text(
      item.statusLabel,
      style: TextStyle(
        fontSize: 11,
        color: _colorFor(item.status),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _EmptyFilterState extends StatelessWidget {
  const _EmptyFilterState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Nenhum item neste filtro',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            'Cole um link ou altere o filtro para ver outros itens.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final VoidCallback onClearFinished;
  final VoidCallback onConfigureEngine;
  final VoidCallback onCheckEngineAvailability;
  final EngineSetupStatus engineStatus;
  final EngineAvailabilityResult engineAvailability;
  final bool isCheckingEngine;

  const _StatusBar({
    required this.onClearFinished,
    required this.onConfigureEngine,
    required this.onCheckEngineAvailability,
    required this.engineStatus,
    required this.engineAvailability,
    required this.isCheckingEngine,
  });

  String get _engineStatusLabel {
    if (isCheckingEngine) return 'Verificando motor...';
    return switch (engineAvailability.status) {
      EngineAvailabilityStatus.available =>
        'Motor disponível: ${engineAvailability.executableLabel} ${engineAvailability.versionLabel ?? ''}'
            .trim(),
      EngineAvailabilityStatus.unavailable => 'Motor indisponível',
      EngineAvailabilityStatus.unknown => switch (engineStatus) {
          EngineSetupStatus.notConfigured => 'Motor externo não configurado',
          EngineSetupStatus.configuredMock =>
            'Motor externo configurado em modo mock',
        },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: _kGreen,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pronto para downloads autorizados',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  _engineStatusLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: onClearFinished,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'Limpar concluídos',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onConfigureEngine,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'Configurar motor',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: isCheckingEngine
                        ? null
                        : onCheckEngineAvailability,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'Verificar motor',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
