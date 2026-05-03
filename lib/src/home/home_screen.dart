import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../downloads/download_item.dart';
import '../downloads/download_format_option.dart';
import '../downloads/download_options.dart';
import '../downloads/download_options_dialog.dart';
import '../downloads/download_options_dialog_result.dart';
import '../downloads/playlist_options_dialog.dart';
import '../downloads/download_preset.dart';
import '../downloads/download_queue_controller.dart';
import '../downloads/download_queue_filter.dart';
import '../downloads/download_sort_option.dart';
import '../engine/download/internal_download_cancellation.dart';
import '../engine/download/internal_download_progress.dart';
import '../engine/download/internal_download_request.dart';
import '../engine/download/internal_download_result.dart';
import '../engine/download/internal_http_downloader.dart';
import '../engine/download/download_output_planner.dart';
import '../engine/download/completed_output_resolver.dart';
import '../engine/download/output_directory_resolver.dart';
import '../engine/download/yt_dlp_output_name_planner.dart';
import '../settings/app_preferences.dart';
import '../settings/output_folder_choice.dart';
import '../settings/preferences_dialog.dart';
import '../system/system_file_opener.dart';
import '../engine/youtube/youtube_url_parser.dart';
import '../engine/youtube/youtube_playlist_url_parser.dart';
import '../engine/yt_dlp/yt_dlp_engine_service.dart';
import '../engine/yt_dlp/yt_dlp_playlist_result.dart';
import 'mock_download_item.dart';

const _kGreen = Color(0xFF2E7D32);
const _kDivider = Color(0xFFE0E0E0);

enum _WatchPlaylistChoice { cancel, video, playlist }

enum _AppMessageType { info, success, failure }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _youtubeUrlParser = YouTubeUrlParser();
  static const _playlistUrlParser = YouTubePlaylistUrlParser();
  DownloadQueueFilter _activeFilter = DownloadQueueFilter.all;
  DownloadSortOption _sortOption = DownloadSortOption.newestFirst;
  AppPreferences _preferences = AppPreferences.defaults;
  DownloadOptions _downloadOptions = const DownloadOptions();
  String _searchQuery = '';
  bool _queueAutoRunEnabled = false;
  bool _queuePumpScheduled = false;
  bool _queueCompletionNotified = false;
  String? _appMessage;
  _AppMessageType _appMessageType = _AppMessageType.info;
  Timer? _appMessageTimer;
  Timer? _fakeProgressTimer;
  Timer? _mockAnalysisTimer;
  final Map<String, InternalDownloadCancellation> _downloadCancellations = {};
  static const _httpDownloader = InternalHttpDownloader();
  static const _outputPlanner = DownloadOutputPlanner();
  static const _outputDirectoryResolver = OutputDirectoryResolver();
  static const _completedOutputResolver = CompletedOutputResolver();
  static const _ytDlpOutputNamePlanner = YtDlpOutputNamePlanner();
  static const _ytDlpEngine = YtDlpEngineService();
  static const _fileOpener = SystemFileOpener();

  late final DownloadQueueController _queueController;

  @override
  void initState() {
    super.initState();
    _downloadOptions = _downloadOptions.copyWith(
      outputFolderLabel: _preferences.outputFolderChoice.label,
    );
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
    _appMessageTimer?.cancel();
    _appMessageTimer = null;
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
    if (_queueAutoRunEnabled) {
      _pumpDownloadQueue();
    }
  }

  void _showInfoMessage(
    String message, {
    Duration duration = const Duration(milliseconds: 1200),
  }) {
    _showAppMessage(message, _AppMessageType.info, duration: duration);
  }

  void _showSuccessMessage(
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showAppMessage(message, _AppMessageType.success, duration: duration);
  }

  void _showFailureMessage(
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showAppMessage(message, _AppMessageType.failure, duration: duration);
  }

  void _showAppMessage(
    String message,
    _AppMessageType type, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!mounted) return;
    _appMessageTimer?.cancel();
    setState(() {
      _appMessage = message;
      _appMessageType = type;
    });
    _appMessageTimer = Timer(duration, _hideAppMessage);
  }

  void _hideAppMessage() {
    if (!mounted) return;
    _appMessageTimer?.cancel();
    _appMessageTimer = null;
    if (_appMessage == null) return;
    setState(() {
      _appMessage = null;
    });
  }

  void _notifyDownloadCompleted(
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!_preferences.notifyWhenDownloadCompletes) return;
    _showSuccessMessage(message, duration: duration);
  }

  void _notifyDownloadFailed(
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!_preferences.notifyWhenDownloadFails) return;
    _showFailureMessage(message, duration: duration);
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
      var effectiveUrl = safeUrl;
      if (_playlistUrlParser.isWatchUrlWithPlaylist(safeUrl)) {
        final choice = await _showWatchPlaylistChoiceDialog();
        if (!mounted) return;
        if (choice == _WatchPlaylistChoice.cancel) {
          _queueController.removeItem(addedItem.id);
          setState(() {});
          return;
        }
        if (choice == _WatchPlaylistChoice.playlist) {
          final playlistUrl = _playlistUrlParser.playlistUrlFromWatchUrl(
            safeUrl,
          );
          if (playlistUrl != null) {
            await _handlePlaylistUrl(playlistUrl, addedItem);
            return;
          }
        } else {
          effectiveUrl = safeUrl;
        }
      }
      if (_playlistUrlParser.isPlaylistUrl(effectiveUrl)) {
        await _handlePlaylistUrl(effectiveUrl, addedItem);
        return;
      }

      if (_youtubeUrlParser.isYouTubeUrl(effectiveUrl)) {
        _showInfoMessage('An?lise do YouTube iniciada');

        try {
          final result = await _ytDlpEngine.analyzeUrl(effectiveUrl);
          if (!mounted) return;

          final updated = _queueController.applyYtDlpAnalysis(
            id: addedItem.id,
            result: result,
            preset: DownloadPreset.fromOptions(_downloadOptions),
          );

          if (updated != null) {
            _queueController.attachMockCommandPreview(
              itemId: addedItem.id,
              outputFolderLabel: _downloadOptions.outputFolderLabel,
            );
            setState(() {});
            if (_preferences.smartModeEnabled) {
              _maybeAutoStartAfterAnalysis(updated);
            } else {
              await _handleManualDownloadChoice(updated);
              if (!mounted) return;
            }
            _showInfoMessage('An?lise yt-dlp conclu?da');
            return;
          }
        } catch (_) {
          if (mounted) {
            _showInfoMessage(
              'yt-dlp n?o dispon?vel; usando an?lise interna limitada.',
              duration: const Duration(milliseconds: 1500),
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
          _showInfoMessage('Usando an?lise interna limitada para YouTube');
          return;
        }

        _scheduleMockAnalysis(addedItem.id);
        return;
      }

      _showInfoMessage('An?lise interna iniciada');

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
        _maybeAutoStartAfterAnalysis(updated);
        _showInfoMessage('An?lise interna conclu?da');
        return;
      }

      _showInfoMessage(
        'An?lise interna falhou; usando resultado mockado',
        duration: const Duration(milliseconds: 1400),
      );
    }

    _scheduleMockAnalysis(addedItem.id);
  }

  void _scheduleMockAnalysis(String itemId) {
    _showInfoMessage('An?lise mockada iniciada');

    _mockAnalysisTimer?.cancel();
    _mockAnalysisTimer = Timer(const Duration(milliseconds: 900), () {
      final updated = _queueController.markItemReadyAfterMockAnalysis(itemId);
      if (!mounted || updated == null) return;

      _queueController.attachMockCommandPreview(
        itemId: itemId,
        outputFolderLabel: _downloadOptions.outputFolderLabel,
      );

      setState(() {});
      _showInfoMessage('An?lise mockada conclu?da');
    });
  }

  Future<void> _handlePlaylistUrl(
    String playlistUrl,
    DownloadItem addedItem,
  ) async {
    _showInfoMessage('Analisando playlist');
    try {
      final playlist = await _ytDlpEngine.analyzePlaylistUrl(playlistUrl);
      if (!mounted) return;
      final selectedEntries = await showDialog<List<YtDlpPlaylistEntry>>(
        context: context,
        builder: (_) => PlaylistOptionsDialog(playlist: playlist),
      );
      if (!mounted) return;
      if (selectedEntries == null || selectedEntries.isEmpty) {
        _queueController.removeItem(addedItem.id);
        setState(() {});
        return;
      }
      _queueController.removeItem(addedItem.id);
      final added = _queueController.addPlaylistEntries(
        entries: selectedEntries,
        transferType: _downloadOptions.transferType,
        formatLabel: _downloadOptions.formatLabel,
        qualityLabel: _downloadOptions.qualityLabel,
        outputFolderLabel: _downloadOptions.outputFolderLabel,
      );
      setState(() {});
      _showInfoMessage(
        'Vídeos adicionados à fila: ${added.length}',
        duration: const Duration(milliseconds: 1400),
      );
    } catch (error) {
      if (!mounted) return;
      const message = 'Não foi possível analisar a playlist';
      _queueController.markItemFailed(addedItem.id, message);
      _showFailureMessage(message);
      setState(() {});
    }
  }

  Future<_WatchPlaylistChoice> _showWatchPlaylistChoiceDialog() async {
    final choice = await showDialog<_WatchPlaylistChoice>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Link com playlist'),
        content: const Text(
          'Este link contém um vídeo dentro de uma playlist. O que deseja baixar?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _WatchPlaylistChoice.cancel);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, _WatchPlaylistChoice.video);
            },
            child: const Text('Vídeo atual'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, _WatchPlaylistChoice.playlist);
            },
            child: const Text('Playlist inteira'),
          ),
        ],
      ),
    );
    return choice ?? _WatchPlaylistChoice.cancel;
  }

  bool _isHttpUrl(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  void _maybeAutoStartAfterAnalysis(DownloadItem? item) {
    if (!_preferences.smartModeEnabled) return;
    if (item == null || item.status != DownloadStatus.ready) return;
    final canAutoStart = item.isYouTubeSource || item.directDownloadUrl != null;
    if (!canAutoStart) return;
    _startItem(item);
    _showInfoMessage('Modo inteligente: download iniciado');
  }

  Future<void> _handleManualDownloadChoice(DownloadItem item) async {
    final result = await showDialog<DownloadOptionsDialogResult>(
      context: context,
      builder: (_) =>
          DownloadOptionsDialog(item: item, initialOptions: _downloadOptions),
    );
    if (!mounted) return;
    if (result == null || !result.startDownload) return;
    if (result.selectedFormatId.trim().isEmpty) return;

    final updatedOptions = _downloadOptions.copyWith(
      transferType: result.transferType,
      qualityLabel: result.qualityLabel,
      formatLabel: result.formatLabel,
    );
    final selected = _queueController.selectFormatForItem(
      item.id,
      result.selectedFormatId,
    );
    if (selected == null) return;
    _queueController.attachMockCommandPreview(
      itemId: item.id,
      outputFolderLabel: updatedOptions.outputFolderLabel,
    );
    setState(() {
      _downloadOptions = updatedOptions;
    });
    _startItem(selected);
  }

  void _applyCurrentPresetToReadyItems() {
    final preset = DownloadPreset.fromOptions(_downloadOptions);
    for (final item in _queueController.items) {
      if (item.status != DownloadStatus.ready) continue;
      if (item.availableFormats.isEmpty) continue;
      _queueController.applyPresetSelectionForItem(item.id, preset);
    }
  }

  void _startQueueAutoRun() {
    if (!_queueController.hasStartableItems) {
      _showInfoMessage('Nenhum item na fila para iniciar.');
      return;
    }
    setState(() {
      _queueAutoRunEnabled = true;
      _queueCompletionNotified = false;
    });
    _pumpDownloadQueue();
    _showInfoMessage('Fila iniciada');
  }

  void _stopQueueAutoRun() {
    if (!_queueAutoRunEnabled) return;
    setState(() {
      _queueAutoRunEnabled = false;
    });
    _showInfoMessage('Fila pausada');
  }

  void _pumpDownloadQueue() {
    if (!_queueAutoRunEnabled) return;
    if (_queuePumpScheduled) return;
    _queuePumpScheduled = true;
    Future<void>.microtask(() {
      _queuePumpScheduled = false;
      if (!mounted || !_queueAutoRunEnabled) return;

      if (!_queueController.hasStartableItems &&
          _queueController.activeTransferCount == 0) {
        setState(() {
          _queueAutoRunEnabled = false;
        });
        if (!_queueCompletionNotified) {
          _queueCompletionNotified = true;
          _showSuccessMessage('Fila concluída');
        }
        return;
      }

      final limit = _preferences.simultaneousDownloads;
      while (_queueController.activeTransferCount < limit) {
        final next = _queueController.nextStartableItem();
        if (next == null) {
          if (_queueController.activeTransferCount == 0 && mounted) {
            setState(() {
              _queueAutoRunEnabled = false;
            });
            if (!_queueCompletionNotified) {
              _queueCompletionNotified = true;
              _showSuccessMessage('Fila concluída');
            }
          }
          return;
        }

        final beforeActive = _queueController.activeTransferCount;
        _startItem(next);
        final afterActive = _queueController.activeTransferCount;
        final stillStartable = _queueController.startableItems.any(
          (item) => item.id == next.id,
        );
        if (afterActive <= beforeActive && stillStartable) {
          break;
        }
      }
    });
  }

  void _startItem(DownloadItem item) {
    if (item.status == DownloadStatus.analyzing) {
      return;
    }

    if (item.isYouTubeSource &&
        item.availableFormats.isEmpty &&
        (item.sourceUrl?.trim().isNotEmpty ?? false)) {
      _analyzeAndStartYouTubeItem(item);
      return;
    }

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

  Future<void> _analyzeAndStartYouTubeItem(DownloadItem item) async {
    final marked = _queueController.markItemAnalyzing(
      item.id,
      'Playlist · analisando vídeo',
    );
    if (marked == null) return;
    if (mounted) {
      setState(() {});
      _showInfoMessage('Analisando vídeo da playlist');
    }

    final sourceUrl = (item.sourceUrl ?? '').trim();
    if (sourceUrl.isEmpty) {
      const message = 'Não foi possível analisar este vídeo';
      _queueController.markItemFailed(item.id, message);
      _showFailureMessage(
        message,
        duration: const Duration(milliseconds: 1400),
      );
      if (mounted) setState(() {});
      if (_queueAutoRunEnabled) {
        _pumpDownloadQueue();
      }
      return;
    }

    try {
      final analysis = await _ytDlpEngine.analyzeUrl(sourceUrl);
      if (!mounted) return;
      final ready = _queueController.applyYtDlpAnalysis(
        id: item.id,
        result: analysis,
        preset: DownloadPreset.fromOptions(_downloadOptions),
      );
      if (ready == null || ready.status != DownloadStatus.ready) {
        _queueController.markItemFailed(item.id, 'Falha ao preparar formatos.');
        setState(() {});
        if (_queueAutoRunEnabled) {
          _pumpDownloadQueue();
        }
        return;
      }
      _queueController.attachMockCommandPreview(
        itemId: item.id,
        outputFolderLabel: _downloadOptions.outputFolderLabel,
      );
      setState(() {});
      _startItem(ready);
    } catch (error) {
      const message = 'Não foi possível analisar este vídeo';
      _queueController.markItemFailed(item.id, message);
      if (mounted) {
        setState(() {});
        _showFailureMessage(
          message,
          duration: const Duration(milliseconds: 1400),
        );
      }
      if (_queueAutoRunEnabled) {
        _pumpDownloadQueue();
      }
    }
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
    if (_queueAutoRunEnabled) {
      _pumpDownloadQueue();
    }
  }

  Future<void> _startInternalDirectDownload(DownloadItem item) async {
    final url = item.directDownloadUrl?.trim() ?? '';
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      const message = 'Falha ao iniciar download direto.';
      _queueController.markItemFailed(item.id, message);
      _notifyDownloadFailed('Download falhou');
      if (mounted) setState(() {});
      if (_queueAutoRunEnabled) {
        _pumpDownloadQueue();
      }
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
      final baseDirectory = await _outputDirectoryResolver.resolve(
        _preferences.outputFolderChoice,
      );
      final outputPlan = await _outputPlanner.plan(
        requestedFileName: fileName,
        baseDirectory: baseDirectory,
      );
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
          final outputFolderLabel = _preferences.outputFolderChoice.label;
          _queueController.markItemCompletedWithOutput(
            id: item.id,
            message: 'Salvo em $outputFolderLabel/ClipFlow',
            outputPath: outputPath,
            outputDirectoryPath: outputDirectoryPath,
          );
          _notifyDownloadCompleted('Download concluído: $savedFileName');
          break;
        case InternalDownloadStatus.canceled:
          _queueController.cancelItem(item.id);
          break;
        case InternalDownloadStatus.failed:
          _queueController.markItemFailed(item.id, result.message);
          _notifyDownloadFailed('Download falhou');
          break;
      }
      setState(() {});
      if (_queueAutoRunEnabled) {
        _pumpDownloadQueue();
      }
    } catch (_) {
      const message = 'Falha ao iniciar download direto.';
      _queueController.markItemFailed(item.id, message);
      _notifyDownloadFailed('Download falhou');
      if (mounted) {
        setState(() {});
      }
      if (_queueAutoRunEnabled) {
        _pumpDownloadQueue();
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
      _notifyDownloadFailed('Download falhou');
      if (mounted) setState(() {});
      if (_queueAutoRunEnabled) {
        _pumpDownloadQueue();
      }
      return;
    }
    final isVideoOnly = YtDlpEngineService.isVideoOnlyOption(selectedFormat);
    if (isVideoOnly) {
      final ffmpeg = await _ytDlpEngine.resolveFfmpeg();
      if (ffmpeg != null && mounted) {
        _showInfoMessage(
          'Baixando vídeo e áudio para merge com FFmpeg.',
          duration: const Duration(seconds: 2),
        );
      }
    }
    final sourceUrl = (item.sourceUrl ?? '').trim();
    if (sourceUrl.isEmpty) {
      const message = 'URL ausente para download.';
      _queueController.markItemFailed(item.id, message);
      _notifyDownloadFailed('Download falhou');
      if (mounted) setState(() {});
      if (_queueAutoRunEnabled) {
        _pumpDownloadQueue();
      }
      return;
    }

    final cancellation = InternalDownloadCancellation();
    _downloadCancellations[item.id] = cancellation;
    final startedAt = DateTime.now();

    try {
      final directory = await _outputDirectoryResolver.resolve(
        _preferences.outputFolderChoice,
      );
      await directory.create(recursive: true);
      final directoryPath = directory.path;
      final requestedBaseName = _safeTitleAsFileBase(item.title);
      final baseName = await _ytDlpOutputNamePlanner.uniqueBaseName(
        directory: directory,
        requestedBaseName: requestedBaseName,
      );
      final outputTemplate =
          '${directory.path}${Platform.pathSeparator}$baseName.%(ext)s';

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
            final outputFolderLabel = _preferences.outputFolderChoice.label;
            _queueController.markItemCompletedWithDirectory(
              id: item.id,
              message: 'Salvo em $outputFolderLabel/ClipFlow',
              outputDirectoryPath: directoryPath,
            );
            _notifyDownloadCompleted(
              'Download concluído, mas o arquivo final não foi localizado automaticamente.',
            );
            break;
          }
          _queueController.markItemCompletedWithOutput(
            id: item.id,
            message:
                'Salvo em ${_preferences.outputFolderChoice.label}/ClipFlow',
            outputPath: outputPath,
            outputDirectoryPath: directoryPath,
          );
          _notifyDownloadCompleted('Download concluído');
          break;
        case InternalDownloadStatus.canceled:
          _queueController.cancelItem(item.id);
          break;
        case InternalDownloadStatus.failed:
          _queueController.markItemFailed(item.id, result.message);
          _notifyDownloadFailed('Download falhou');
          break;
      }
      setState(() {});
      if (_queueAutoRunEnabled) {
        _pumpDownloadQueue();
      }
    } catch (_) {
      const message = 'Falha ao iniciar download via yt-dlp.';
      _queueController.markItemFailed(item.id, message);
      _notifyDownloadFailed('Download falhou');
      if (mounted) setState(() {});
      if (_queueAutoRunEnabled) {
        _pumpDownloadQueue();
      }
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

    _showInfoMessage(
      'Itens finalizados removidos: $removed',
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _openPreferencesDialog() async {
    final updated = await showDialog<AppPreferences>(
      context: context,
      builder: (_) => PreferencesDialog(initialPreferences: _preferences),
    );
    if (!mounted || updated == null) return;
    setState(() {
      _preferences = updated;
      _downloadOptions = _downloadOptions.copyWith(
        outputFolderLabel: updated.outputFolderChoice.label,
      );
    });
    _showInfoMessage('Preferências atualizadas');
    if (_queueAutoRunEnabled) {
      _pumpDownloadQueue();
    }
  }

  Future<void> _openDownloadedFile(DownloadItem item) async {
    final outputPath = item.outputPath?.trim() ?? '';
    if (outputPath.isEmpty) {
      if (!mounted) return;
      _showFailureMessage('Arquivo não encontrado. Abra a pasta de downloads.');
      return;
    }
    if (!await File(outputPath).exists()) {
      if (!mounted) return;
      _showFailureMessage('Arquivo não encontrado. Abra a pasta de downloads.');
      return;
    }
    try {
      await _fileOpener.openFile(outputPath);
    } catch (_) {
      if (!mounted) return;
      _showFailureMessage('Não foi possível abrir o arquivo.');
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
      _showFailureMessage('Não foi possível abrir a pasta.');
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
      final directory = await _outputDirectoryResolver.resolve(
        _preferences.outputFolderChoice,
      );
      await directory.create(recursive: true);
      await _fileOpener.openFolder(directory.path);
    } catch (_) {
      if (!mounted) return;
      _showFailureMessage('Não foi possível abrir a pasta de downloads.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _queueController.filteredItems(
      filter: _activeFilter,
      searchQuery: _searchQuery,
      sortOption: _sortOption,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          Column(
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
                onTransferChanged: (type) => setState(() {
                  _downloadOptions = _downloadOptions.copyWith(
                    transferType: type,
                  );
                  _applyCurrentPresetToReadyItems();
                }),
                onQualityChanged: (value) => setState(() {
                  _downloadOptions = _downloadOptions.copyWith(
                    qualityLabel: value,
                  );
                  _applyCurrentPresetToReadyItems();
                }),
                onFormatChanged: (value) => setState(() {
                  _downloadOptions = _downloadOptions.copyWith(
                    formatLabel: value,
                  );
                  _applyCurrentPresetToReadyItems();
                }),
                onOutputFolderChanged: (value) => setState(() {
                  if (value == 'Navegar...') {
                    _showInfoMessage(
                      'Escolha de pasta personalizada virá em rodada futura.',
                      duration: const Duration(milliseconds: 1400),
                    );
                    return;
                  }

                  final choice = switch (value) {
                    'Vídeos' => const OutputFolderChoice(
                      type: OutputFolderType.videos,
                      label: 'Vídeos',
                    ),
                    'Documentos' => const OutputFolderChoice(
                      type: OutputFolderType.documents,
                      label: 'Documentos',
                    ),
                    _ => OutputFolderChoice.downloads,
                  };
                  _preferences = _preferences.copyWith(
                    outputFolderChoice: choice,
                  );
                  _downloadOptions = _downloadOptions.copyWith(
                    outputFolderLabel: choice.label,
                  );
                }),
                smartModeEnabled: _preferences.smartModeEnabled,
                onSmartModeChanged: (value) => setState(() {
                  _preferences = _preferences.copyWith(smartModeEnabled: value);
                }),
                onPaste: _handlePaste,
                onOpenPreferences: _openPreferencesDialog,
              ),
              const Divider(height: 1, thickness: 1, color: _kDivider),
              _FilterTabs(
                selectedFilter: _activeFilter,
                itemCountLabel: _queueController.filteredItemCountLabel(
                  filter: _activeFilter,
                  searchQuery: _searchQuery,
                  sortOption: _sortOption,
                ),
                onSearchChanged: (value) =>
                    setState(() => _searchQuery = value),
                onChanged: (filter) => setState(() => _activeFilter = filter),
                sortOption: _sortOption,
                onSortChanged: (option) => setState(() => _sortOption = option),
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
                            onOpenFile: () =>
                                _openDownloadedFile(visibleItems[i]),
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
                onToggleQueueAutoRun: _queueAutoRunEnabled
                    ? _stopQueueAutoRun
                    : _startQueueAutoRun,
                queueAutoRunEnabled: _queueAutoRunEnabled,
                simultaneousLimit: _preferences.simultaneousDownloads,
              ),
            ],
          ),
          if (_appMessage != null)
            Positioned(
              top: 92,
              right: 16,
              child: _AppMessageBanner(
                message: _appMessage!,
                type: _appMessageType,
                onClose: _hideAppMessage,
              ),
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
  final bool smartModeEnabled;
  final ValueChanged<bool> onSmartModeChanged;
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
    required this.smartModeEnabled,
    required this.onSmartModeChanged,
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
                  Tooltip(
                    message:
                        'Quando ativado, baixa automaticamente após colar link.',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: smartModeEnabled,
                          onChanged: onSmartModeChanged,
                          activeThumbColor: _kGreen,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        Text(
                          'Modo inteligente',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: smartModeEnabled
                                ? _kGreen
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _SelectorButton<DownloadTransferType>(
                    valueLabel: selectedTransferLabel,
                    options: const {
                      DownloadTransferType.video: 'V\u00eddeo',
                      DownloadTransferType.audio: '\u00c1udio',
                      DownloadTransferType.subtitles: 'Legendas',
                    },
                    onChanged: onTransferChanged,
                  ),
                  const SizedBox(width: 8),
                  _SelectorButton<String>(
                    valueLabel: selectedQualityLabel,
                    options: const {
                      '\u00d3tima': '\u00d3tima',
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
                      'M4A': 'M4A',
                      'WEBM': 'WEBM',
                    },
                    onChanged: onFormatChanged,
                  ),
                  const SizedBox(width: 8),
                  _SelectorButton<String>(
                    valueLabel: selectedOutputFolderLabel,
                    options: const {
                      'V\u00eddeos': 'V\u00eddeos',
                      'Downloads': 'Downloads',
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
  final DownloadSortOption sortOption;
  final String itemCountLabel;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<DownloadQueueFilter> onChanged;
  final ValueChanged<DownloadSortOption> onSortChanged;

  const _FilterTabs({
    required this.selectedFilter,
    required this.sortOption,
    required this.itemCountLabel,
    required this.onSearchChanged,
    required this.onChanged,
    required this.onSortChanged,
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
          const SizedBox(width: 8),
          _SortControls(sortOption: sortOption, onSortChanged: onSortChanged),
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

class _SortControls extends StatelessWidget {
  final DownloadSortOption sortOption;
  final ValueChanged<DownloadSortOption> onSortChanged;

  const _SortControls({required this.sortOption, required this.onSortChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Ordenar por', style: TextStyle(fontSize: 12)),
        const SizedBox(width: 6),
        DropdownButton<DownloadSortField>(
          value: sortOption.field,
          isDense: true,
          onChanged: (value) {
            if (value == null) return;
            onSortChanged(
              DownloadSortOption(field: value, direction: sortOption.direction),
            );
          },
          items: const [
            DropdownMenuItem(
              value: DownloadSortField.added,
              child: Text('Mais recentes', style: TextStyle(fontSize: 12)),
            ),
            DropdownMenuItem(
              value: DownloadSortField.title,
              child: Text('Nome', style: TextStyle(fontSize: 12)),
            ),
            DropdownMenuItem(
              value: DownloadSortField.status,
              child: Text('Status', style: TextStyle(fontSize: 12)),
            ),
            DropdownMenuItem(
              value: DownloadSortField.type,
              child: Text('Tipo', style: TextStyle(fontSize: 12)),
            ),
            DropdownMenuItem(
              value: DownloadSortField.author,
              child: Text('Autor', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(width: 6),
        DropdownButton<DownloadSortDirection>(
          value: sortOption.direction,
          isDense: true,
          onChanged: (value) {
            if (value == null) return;
            onSortChanged(
              DownloadSortOption(field: sortOption.field, direction: value),
            );
          },
          items: const [
            DropdownMenuItem(
              value: DownloadSortDirection.descending,
              child: Text('Desc', style: TextStyle(fontSize: 12)),
            ),
            DropdownMenuItem(
              value: DownloadSortDirection.ascending,
              child: Text('Asc', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
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
    final isDownloading = item.status == DownloadStatus.downloading;
    final isMerging = item.sourceLabel == 'Mesclando com FFmpeg';
    final isPlaylistQueuedPendingAnalysis =
        item.isYouTubeSource &&
        item.availableFormats.isEmpty &&
        item.status == DownloadStatus.queued;
    final statusText = _statusText(item, isMerging);
    final metadataParts = isPlaylistQueuedPendingAnalysis
        ? <String>[item.durationLabel, item.sourceLabel]
        : <String>[
            item.durationLabel,
            item.sizeLabel,
            item.selectedFormatSummary ?? item.formatLabel,
            statusText,
          ];
    final completedOutputLabel =
        item.outputSummaryLabel ??
        (item.outputDirectoryPath != null ? 'Salvo em pasta' : null);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ThumbnailPreview(item: item),
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
                    if (item.authorLabel != null &&
                        item.authorLabel!.trim().isNotEmpty)
                      Text(
                        item.authorLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    if (item.authorLabel != null &&
                        item.authorLabel!.trim().isNotEmpty)
                      const SizedBox(height: 3),
                    Text(
                      metadataParts.join(' · '),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isMerging)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Mesclando com FFmpeg',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blueGrey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (item.status == DownloadStatus.ready &&
                        item.availableFormats.isNotEmpty)
                      _FormatSelector(item: item, onSelected: onFormatSelected),
                    if (item.selectedFormatSummary != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item.selectedFormatSummary!,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LinearProgressIndicator(
                              value: item.progress,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation(_kGreen),
                              minHeight: 3,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${(item.progress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (item.status == DownloadStatus.completed &&
                        completedOutputLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          completedOutputLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.end,
                  children: [
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
                    _StatusBadge(item: item),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
      ],
    );
  }

  String _statusText(DownloadItem item, bool isMerging) {
    if (isMerging) return 'Mesclando com FFmpeg';
    final isPlaylistQueuedPendingAnalysis =
        item.isYouTubeSource &&
        item.availableFormats.isEmpty &&
        item.status == DownloadStatus.queued;
    if (isPlaylistQueuedPendingAnalysis) return 'Na fila';
    return switch (item.status) {
      DownloadStatus.queued => 'Aguardando',
      DownloadStatus.ready => 'Pronto',
      DownloadStatus.downloading => 'Baixando',
      DownloadStatus.analyzing => 'Analisando',
      DownloadStatus.completed => 'Concluído',
      DownloadStatus.failed => 'Falhou',
      DownloadStatus.canceled => 'Cancelado',
      DownloadStatus.paused => 'Aguardando',
    };
  }
}

class _ThumbnailPreview extends StatelessWidget {
  final DownloadItem item;

  const _ThumbnailPreview({required this.item});

  @override
  Widget build(BuildContext context) {
    final url = item.thumbnailUrl;
    if (url != null && url.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Image.network(
          url,
          width: 78,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 78,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Icon(
        Icons.play_arrow_rounded,
        color: Colors.white54,
        size: 26,
      ),
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
            tooltip:
                item.isYouTubeSource &&
                    item.availableFormats.isEmpty &&
                    item.status == DownloadStatus.queued
                ? 'Analisar e baixar'
                : 'Iniciar',
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
    final isMerging = item.sourceLabel == 'Mesclando com FFmpeg';
    final isPlaylistQueuedPendingAnalysis =
        item.isYouTubeSource &&
        item.availableFormats.isEmpty &&
        item.status == DownloadStatus.queued;
    final statusLabel = isMerging
        ? 'Mesclando com FFmpeg'
        : isPlaylistQueuedPendingAnalysis
        ? 'Na fila'
        : switch (item.status) {
            DownloadStatus.queued => 'Aguardando',
            DownloadStatus.ready => 'Pronto',
            DownloadStatus.downloading => 'Baixando',
            DownloadStatus.analyzing => 'Analisando',
            DownloadStatus.completed => 'Concluído',
            DownloadStatus.failed => 'Falhou',
            DownloadStatus.canceled => 'Cancelado',
            DownloadStatus.paused => 'Aguardando',
          };
    return Text(
      statusLabel,
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

class _AppMessageBanner extends StatelessWidget {
  final String message;
  final _AppMessageType type;
  final VoidCallback onClose;

  const _AppMessageBanner({
    required this.message,
    required this.type,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, IconData icon) = switch (type) {
      _AppMessageType.info => (
        const Color(0xFFEAF2FF),
        const Color(0xFF1D4ED8),
        Icons.info_outline,
      ),
      _AppMessageType.success => (
        const Color(0xFFEAF7EE),
        const Color(0xFF166534),
        Icons.check_circle_outline,
      ),
      _AppMessageType.failure => (
        const Color(0xFFFDECEC),
        const Color(0xFFB91C1C),
        Icons.error_outline,
      ),
    };
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: fg.withValues(alpha: 0.24)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                onPressed: onClose,
                icon: Icon(Icons.close, color: fg),
                tooltip: 'Fechar',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final VoidCallback onClearFinished;
  final VoidCallback onShowEngineInfo;
  final VoidCallback onToggleQueueAutoRun;
  final bool queueAutoRunEnabled;
  final int simultaneousLimit;

  const _StatusBar({
    required this.onClearFinished,
    required this.onShowEngineInfo,
    required this.onToggleQueueAutoRun,
    required this.queueAutoRunEnabled,
    required this.simultaneousLimit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
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
                  'Pronto para downloads',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Fila: até $simultaneousLimit simultâneo(s)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
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
                  const SizedBox(width: 8),
                  Tooltip(
                    message: queueAutoRunEnabled
                        ? 'Parar de iniciar novos downloads'
                        : 'Iniciar downloads pendentes respeitando o limite de simultaneidade',
                    child: OutlinedButton(
                      onPressed: onToggleQueueAutoRun,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(
                        queueAutoRunEnabled ? 'Parar fila' : 'Iniciar fila',
                        style: const TextStyle(fontSize: 13),
                      ),
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
