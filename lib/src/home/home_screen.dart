import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../downloads/download_item.dart';
import '../downloads/download_format_option.dart';
import '../downloads/download_options.dart';
import '../downloads/download_queue_controller.dart';
import '../downloads/download_queue_filter.dart';
import '../engine/download/internal_download_cancellation.dart';
import '../engine/download/internal_download_progress.dart';
import '../engine/download/internal_download_request.dart';
import '../engine/download/internal_download_result.dart';
import '../engine/download/internal_http_downloader.dart';
import '../engine/download/download_output_planner.dart';
import '../engine/download/completed_output_resolver.dart';
import '../settings/app_preferences.dart';
import '../settings/preferences_dialog.dart';
import '../system/system_file_opener.dart';
import '../engine/youtube/youtube_url_parser.dart';
import '../engine/yt_dlp/yt_dlp_engine_service.dart';
import 'mock_download_item.dart';

const _kGreen = Color(0xFF2E7D32);
const _kDivider = Color(0xFFE0E0E0);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _youtubeUrlParser = YouTubeUrlParser();
  DownloadQueueFilter _activeFilter = DownloadQueueFilter.all;
  AppPreferences _preferences = AppPreferences.defaults;
  DownloadOptions _downloadOptions = const DownloadOptions();
  String _searchQuery = '';
  Timer? _fakeProgressTimer;
  Timer? _mockAnalysisTimer;
  final Map<String, InternalDownloadCancellation> _downloadCancellations = {};
  static const _httpDownloader = InternalHttpDownloader();
  static const _outputPlanner = DownloadOutputPlanner();
  static const _completedOutputResolver = CompletedOutputResolver();
  static const _ytDlpEngine = YtDlpEngineService();
  static const _fileOpener = SystemFileOpener();

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
    for (final cancellation in _downloadCancellations.values) {
      cancellation.cancel();
    }
    _downloadCancellations.clear();
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
    if (changed <= 0) {
      _fakeProgressTimer?.cancel();
      _fakeProgressTimer = null;
      return;
    }
    setState(() {});
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

    final safeUrl = (url ?? '').trim();
    if (_isHttpUrl(safeUrl)) {
      if (_youtubeUrlParser.isYouTubeUrl(safeUrl)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Análise do YouTube iniciada'),
            duration: Duration(milliseconds: 1200),
          ),
        );

        try {
          final result = await _ytDlpEngine.analyzeUrl(safeUrl);
          if (!mounted) return;

          final updated = _queueController.applyYtDlpAnalysis(
            id: addedItem.id,
            result: result,
          );

          if (updated != null) {
            _queueController.attachMockCommandPreview(
              itemId: addedItem.id,
              outputFolderLabel: _downloadOptions.outputFolderLabel,
            );
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Análise yt-dlp concluída'),
                duration: Duration(milliseconds: 1200),
              ),
            );
            return;
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'yt-dlp n\u00e3o dispon\u00edvel; usando an\u00e1lise interna limitada.',
                ),
                duration: Duration(milliseconds: 1500),
              ),
            );
          }
        }

        final fallbackUpdated = _queueController
            .markItemReadyAfterInternalAnalysis(
              id: addedItem.id,
              outputFolderLabel: _downloadOptions.outputFolderLabel,
            );
        if (fallbackUpdated != null &&
            fallbackUpdated.status == DownloadStatus.ready) {
          _queueController.attachMockCommandPreview(
            itemId: addedItem.id,
            outputFolderLabel: _downloadOptions.outputFolderLabel,
          );
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usando análise interna limitada para YouTube'),
              duration: Duration(milliseconds: 1200),
            ),
          );
          return;
        }

        _scheduleMockAnalysis(addedItem.id);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An\u00e1lise interna iniciada'),
          duration: Duration(milliseconds: 1200),
        ),
      );

      final updated = _queueController.markItemReadyAfterInternalAnalysis(
        id: addedItem.id,
        outputFolderLabel: _downloadOptions.outputFolderLabel,
      );

      if (updated != null && updated.status == DownloadStatus.ready) {
        _queueController.attachMockCommandPreview(
          itemId: addedItem.id,
          outputFolderLabel: _downloadOptions.outputFolderLabel,
        );
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An\u00e1lise interna conclu\u00edda'),
            duration: Duration(milliseconds: 1200),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'An\u00e1lise interna falhou; usando resultado mockado',
          ),
          duration: Duration(milliseconds: 1400),
        ),
      );
    }

    _scheduleMockAnalysis(addedItem.id);
  }

  void _scheduleMockAnalysis(String itemId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('An\u00e1lise mockada iniciada'),
        duration: Duration(milliseconds: 1200),
      ),
    );

    _mockAnalysisTimer?.cancel();
    _mockAnalysisTimer = Timer(const Duration(milliseconds: 900), () {
      final updated = _queueController.markItemReadyAfterMockAnalysis(itemId);
      if (!mounted || updated == null) return;

      _queueController.attachMockCommandPreview(
        itemId: itemId,
        outputFolderLabel: _downloadOptions.outputFolderLabel,
      );

      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An\u00e1lise mockada conclu\u00edda'),
          duration: Duration(milliseconds: 1200),
        ),
      );
    });
  }

  bool _isHttpUrl(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  void _startItem(DownloadItem item) {
    final started = _queueController.markItemDownloading(item.id);
    if (started == null) return;

    setState(() {});
    if (started.directDownloadUrl != null) {
      _startInternalDirectDownload(started);
      return;
    }
    if (started.isYouTubeSource) {
      _startYouTubeWithYtDlpDownload(started);
      return;
    }

    _ensureFakeProgressTimer();
  }

  void _pauseItem(DownloadItem item) {
    final paused = _queueController.pauseItem(item.id);
    if (paused == null) return;

    setState(() {});
    _stopFakeProgressTimerIfIdle();
  }

  void _cancelItem(DownloadItem item) {
    final cancellation = _downloadCancellations[item.id];
    cancellation?.cancel();

    final canceled = _queueController.cancelItem(item.id);
    if (canceled == null) return;

    setState(() {});
    _stopFakeProgressTimerIfIdle();
  }

  Future<void> _startInternalDirectDownload(DownloadItem item) async {
    final url = item.directDownloadUrl?.trim() ?? '';
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      _queueController.markItemFailed(
        item.id,
        'Falha ao iniciar download direto.',
      );
      if (mounted) setState(() {});
      return;
    }

    final cancellation = InternalDownloadCancellation();
    _downloadCancellations[item.id] = cancellation;

    IOSink? sink;
    late String outputPath;
    late String outputDirectoryPath;
    String? savedFileName;
    try {
      final fileName = (item.outputFileName?.trim().isNotEmpty ?? false)
          ? item.outputFileName!.trim()
          : 'clipflow-download.bin';
      final outputPlan = await _outputPlanner.plan(requestedFileName: fileName);
      outputPath = outputPlan.file.path;
      outputDirectoryPath = outputPlan.directory.path;
      savedFileName = outputPlan.fileName;
      sink = outputPlan.file.openWrite();

      final result = await _httpDownloader.download(
        request: InternalDownloadRequest(sourceUri: uri, fileName: fileName),
        sink: sink,
        cancellation: cancellation,
        onProgress: (InternalDownloadProgress progress) {
          final fraction = progress.fraction;
          if (fraction == null) return;
          _queueController.updateItemProgress(item.id, fraction);
          if (mounted) {
            setState(() {});
          }
        },
      );

      if (!mounted) return;
      switch (result.status) {
        case InternalDownloadStatus.completed:
          _queueController.markItemCompletedWithOutput(
            id: item.id,
            message: 'Salvo em Downloads/ClipFlow',
            outputPath: outputPath,
            outputDirectoryPath: outputDirectoryPath,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download concluído: $savedFileName'),
              duration: const Duration(seconds: 2),
            ),
          );
          break;
        case InternalDownloadStatus.canceled:
          _queueController.cancelItem(item.id);
          break;
        case InternalDownloadStatus.failed:
          _queueController.markItemFailed(item.id, result.message);
          break;
      }
      setState(() {});
    } catch (_) {
      _queueController.markItemFailed(
        item.id,
        'Falha ao iniciar download direto.',
      );
      if (mounted) {
        setState(() {});
      }
    } finally {
      await sink?.close();
      _downloadCancellations.remove(item.id);
    }
  }

  Future<void> _startYouTubeWithYtDlpDownload(DownloadItem item) async {
    final selectedFormat = _queueController.selectedFormatForItem(item.id);
    if (selectedFormat == null) {
      _queueController.markItemFailed(
        item.id,
        'Selecione um formato antes de iniciar.',
      );
      if (mounted) setState(() {});
      return;
    }
    final isVideoOnly = YtDlpEngineService.isVideoOnlyOption(selectedFormat);
    if (isVideoOnly) {
      final ffmpeg = await _ytDlpEngine.resolveFfmpeg();
      if (ffmpeg != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Baixando vídeo e áudio para merge com FFmpeg.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
    final sourceUrl = (item.sourceUrl ?? '').trim();
    if (sourceUrl.isEmpty) {
      _queueController.markItemFailed(item.id, 'URL ausente para download.');
      if (mounted) setState(() {});
      return;
    }

    final cancellation = InternalDownloadCancellation();
    _downloadCancellations[item.id] = cancellation;
    final startedAt = DateTime.now();

    try {
      final directory = _outputPlanner.defaultDownloadDirectory();
      await directory.create(recursive: true);
      final directoryPath = directory.path;
      final baseName = _safeTitleAsFileBase(item.title);
      final outputTemplate =
          '${directory.path}${Platform.pathSeparator}$baseName-%(id)s.%(ext)s';

      final result = await _ytDlpEngine.download(
        url: sourceUrl,
        formatId: selectedFormat.id,
        selectedFormatLabel: selectedFormat.formatLabel,
        selectedFormatIsVideoOnly: isVideoOnly,
        outputTemplate: outputTemplate,
        cancellation: cancellation,
        onLogLine: (line) {
          final lower = line.toLowerCase();
          if (lower.contains('[merger]') || lower.contains('merging formats')) {
            final updated = _queueController.markItemMerging(item.id);
            if (updated != null && mounted) {
              setState(() {});
            }
          }
        },
        onProgress: (progress) {
          final fraction = progress.fraction;
          if (fraction == null) return;
          _queueController.updateItemProgress(item.id, fraction);
          if (mounted) setState(() {});
        },
      );

      if (!mounted) return;
      switch (result.status) {
        case InternalDownloadStatus.completed:
          final outputPath = await _resolveCompletedOutputPath(
            reportedOutputPath: result.outputPath,
            outputDirectoryPath: directoryPath,
            baseName: baseName,
            startedAt: startedAt,
          );
          if (!mounted) return;
          if (outputPath == null) {
            _queueController.markItemCompletedWithDirectory(
              id: item.id,
              message: 'Salvo em Downloads/ClipFlow',
              outputDirectoryPath: directoryPath,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Download concluído, mas o arquivo final não foi localizado automaticamente.',
                ),
                duration: Duration(seconds: 2),
              ),
            );
            break;
          }
          _queueController.markItemCompletedWithOutput(
            id: item.id,
            message: 'Salvo em Downloads/ClipFlow',
            outputPath: outputPath,
            outputDirectoryPath: directoryPath,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download concluído em Downloads/ClipFlow'),
              duration: Duration(seconds: 2),
            ),
          );
          break;
        case InternalDownloadStatus.canceled:
          _queueController.cancelItem(item.id);
          break;
        case InternalDownloadStatus.failed:
          _queueController.markItemFailed(item.id, result.message);
          break;
      }
      setState(() {});
    } catch (_) {
      _queueController.markItemFailed(
        item.id,
        'Falha ao iniciar download via yt-dlp.',
      );
      if (mounted) setState(() {});
    } finally {
      _downloadCancellations.remove(item.id);
    }
  }

  String _safeTitleAsFileBase(String title) {
    final cleaned = title
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return 'youtube-video';
    if (cleaned.length <= 80) return cleaned;
    return cleaned.substring(0, 80).trim();
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
      outputFolderLabel: _downloadOptions.outputFolderLabel,
    );
    setState(() {});
  }

  Future<void> _showInternalEngineDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Motor interno'),
          content: const Text(
            'ClipFlow usa um motor interno pr\u00f3prio para reconhecer links do YouTube e preparar downloads autorizados. Motor yt-dlp ativo para YouTube. FFmpeg ainda n\u00e3o configurado; qualidades altas podem exigir merge.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendi'),
            ),
          ],
        );
      },
    );
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

  Future<void> _openPreferencesDialog() async {
    final updated = await showDialog<AppPreferences>(
      context: context,
      builder: (_) => PreferencesDialog(initialPreferences: _preferences),
    );
    if (!mounted || updated == null) return;
    setState(() => _preferences = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preferências atualizadas'),
        duration: Duration(milliseconds: 1200),
      ),
    );
  }

  Future<void> _openDownloadedFile(DownloadItem item) async {
    final outputPath = item.outputPath?.trim() ?? '';
    if (outputPath.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arquivo não encontrado. Abra a pasta de downloads.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    if (!await File(outputPath).exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arquivo não encontrado. Abra a pasta de downloads.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    try {
      await _fileOpener.openFile(outputPath);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o arquivo.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openDownloadFolder(DownloadItem item) async {
    final outputDirectoryPath = item.outputDirectoryPath?.trim() ?? '';
    if (outputDirectoryPath.isEmpty) return;
    try {
      final directory = Directory(outputDirectoryPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      await _fileOpener.openFolder(outputDirectoryPath);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir a pasta.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<String?> _resolveCompletedOutputPath({
    required String? reportedOutputPath,
    required String outputDirectoryPath,
    required String baseName,
    DateTime? startedAt,
  }) async {
    return _completedOutputResolver.resolve(
      reportedOutputPath: reportedOutputPath,
      outputDirectoryPath: outputDirectoryPath,
      baseName: baseName,
      startedAt: startedAt,
    );
  }

  Future<void> _openDownloadsRootFolder() async {
    try {
      final directory = _outputPlanner.defaultDownloadDirectory();
      await directory.create(recursive: true);
      await _fileOpener.openFolder(directory.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir a pasta de downloads.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
          _MenuBar(
            onOpenDownloadsFolder: () => _openDownloadsRootFolder(),
            onOpenPreferences: _openPreferencesDialog,
          ),
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
            onOpenPreferences: _openPreferencesDialog,
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
                        onOpenFile: () => _openDownloadedFile(visibleItems[i]),
                        onOpenFolder: () =>
                            _openDownloadFolder(visibleItems[i]),
                        onFormatSelected: (formatId) =>
                            _selectFormatForItem(visibleItems[i], formatId),
                      ),
                    ),
            ),
          ),
          _StatusBar(
            onClearFinished: _clearFinishedItems,
            onShowEngineInfo: _showInternalEngineDialog,
          ),
        ],
      ),
    );
  }
}

class _MenuBar extends StatelessWidget {
  final VoidCallback onOpenDownloadsFolder;
  final VoidCallback onOpenPreferences;

  const _MenuBar({
    required this.onOpenDownloadsFolder,
    required this.onOpenPreferences,
  });

  static const _items = ['Editar', 'Ver', 'Ajuda'];

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
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'open_downloads') {
                  onOpenDownloadsFolder();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem<String>(
                  value: 'open_downloads',
                  child: Text('Abrir pasta de downloads'),
                ),
              ],
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Text(
                  'Arquivo',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'preferences') {
                  onOpenPreferences();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem<String>(
                  value: 'preferences',
                  child: Text('Preferências'),
                ),
              ],
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Text(
                  'Ferramentas',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
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
  final VoidCallback onOpenPreferences;

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
    required this.onOpenPreferences,
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
                      DownloadTransferType.video: 'V\u00eddeo',
                      DownloadTransferType.audio: '\u00c1udio',
                      DownloadTransferType.subtitles: 'Legendas',
                      DownloadTransferType.audioTracks: 'Faixas de \u00e1udio',
                    },
                    onChanged: onTransferChanged,
                  ),
                  const SizedBox(width: 8),
                  _SelectorButton<String>(
                    valueLabel: selectedQualityLabel,
                    options: const {
                      '\u00d3tima': '\u00d3tima',
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
                      'Autom\u00e1tico': 'Autom\u00e1tico',
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
                      'V\u00eddeos': 'V\u00eddeos',
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
            onPressed: onOpenPreferences,
            tooltip: 'Configura\u00e7\u00f5es',
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
  final VoidCallback onOpenFile;
  final VoidCallback onOpenFolder;
  final ValueChanged<String> onFormatSelected;

  const _DownloadListItem({
    required this.item,
    required this.onStart,
    required this.onPause,
    required this.onCancel,
    required this.onRemove,
    required this.onOpenFile,
    required this.onOpenFolder,
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
                onOpenFile:
                    item.status == DownloadStatus.completed &&
                        (item.outputPath?.isNotEmpty ?? false)
                    ? onOpenFile
                    : null,
                onOpenFolder:
                    item.status == DownloadStatus.completed &&
                        (item.outputDirectoryPath?.isNotEmpty ?? false)
                    ? onOpenFolder
                    : null,
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
  final VoidCallback? onOpenFile;
  final VoidCallback? onOpenFolder;

  const _ItemActions({
    required this.item,
    required this.onStart,
    required this.onPause,
    required this.onCancel,
    required this.onRemove,
    this.onOpenFile,
    this.onOpenFolder,
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
        if (onOpenFile != null)
          IconButton(
            icon: const Icon(Icons.open_in_new, size: 18),
            onPressed: onOpenFile,
            tooltip: 'Abrir arquivo',
            visualDensity: VisualDensity.compact,
          ),
        if (onOpenFolder != null)
          IconButton(
            icon: const Icon(Icons.folder_open, size: 18),
            onPressed: onOpenFolder,
            tooltip: 'Abrir pasta',
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
  final VoidCallback onShowEngineInfo;

  const _StatusBar({
    required this.onClearFinished,
    required this.onShowEngineInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
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
                const Text(
                  'Motor yt-dlp ativo para YouTube',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const Text(
                  'FFmpeg ainda n\u00e3o configurado; qualidades altas podem exigir merge.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white70, fontSize: 10),
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
                      'Limpar conclu\u00eddos',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onShowEngineInfo,
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
                      'Sobre o motor',
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
