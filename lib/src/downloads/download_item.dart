import 'download_options.dart';
import 'download_format_option.dart';

enum DownloadStatus {
  queued,
  analyzing,
  ready,
  downloading,
  paused,
  completed,
  failed,
  canceled,
}

class DownloadItem {
  final String id;
  final String title;
  final String? sourceUrl;
  final String durationLabel;
  final String sizeLabel;
  final String formatLabel;
  final String qualityLabel;
  final String fpsLabel;
  final String sourceLabel;
  final DateTime? addedAt;
  final DownloadTransferType transferType;
  final DownloadStatus status;
  final double progress;
  final List<DownloadFormatOption> availableFormats;
  final String? selectedFormatId;
  final String? commandPreviewLabel;
  final String? thumbnailUrl;
  final String? authorLabel;
  final String? selectedFormatSummary;
  final String? directDownloadUrl;
  final String? outputFileName;
  final String? outputPath;
  final String? outputDirectoryPath;
  final String? outputSummaryLabel;
  final bool isYouTubeSource;

  DownloadItem({
    required this.id,
    required this.title,
    this.sourceUrl,
    required this.durationLabel,
    required this.sizeLabel,
    required this.formatLabel,
    required this.qualityLabel,
    required this.fpsLabel,
    required this.sourceLabel,
    this.addedAt,
    this.transferType = DownloadTransferType.video,
    this.status = DownloadStatus.queued,
    List<DownloadFormatOption> availableFormats = const [],
    this.selectedFormatId,
    this.commandPreviewLabel,
    this.thumbnailUrl,
    this.authorLabel,
    this.selectedFormatSummary,
    this.directDownloadUrl,
    this.outputFileName,
    this.outputPath,
    this.outputDirectoryPath,
    this.outputSummaryLabel,
    this.isYouTubeSource = false,
    double progress = 0.0,
  }) : progress = progress.clamp(0.0, 1.0),
       availableFormats = List.unmodifiable(availableFormats);

  String get metadataLabel =>
      '$durationLabel \u00b7 $sizeLabel \u00b7 $formatLabel \u00b7 $qualityLabel \u00b7 $fpsLabel \u00b7 $sourceLabel';

  String get statusLabel => switch (status) {
    DownloadStatus.queued => 'Na fila',
    DownloadStatus.analyzing => 'Analisando',
    DownloadStatus.ready => 'Pronto',
    DownloadStatus.downloading => 'Baixando',
    DownloadStatus.paused => 'Pausado',
    DownloadStatus.completed => 'Conclu\u00eddo',
    DownloadStatus.failed => 'Falhou',
    DownloadStatus.canceled => 'Cancelado',
  };

  DownloadItem copyWith({
    String? id,
    String? title,
    String? sourceUrl,
    String? durationLabel,
    String? sizeLabel,
    String? formatLabel,
    String? qualityLabel,
    String? fpsLabel,
    String? sourceLabel,
    DateTime? addedAt,
    DownloadTransferType? transferType,
    DownloadStatus? status,
    double? progress,
    List<DownloadFormatOption>? availableFormats,
    String? selectedFormatId,
    String? commandPreviewLabel,
    String? thumbnailUrl,
    String? authorLabel,
    String? selectedFormatSummary,
    String? directDownloadUrl,
    String? outputFileName,
    String? outputPath,
    String? outputDirectoryPath,
    String? outputSummaryLabel,
    bool? isYouTubeSource,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      title: title ?? this.title,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      durationLabel: durationLabel ?? this.durationLabel,
      sizeLabel: sizeLabel ?? this.sizeLabel,
      formatLabel: formatLabel ?? this.formatLabel,
      qualityLabel: qualityLabel ?? this.qualityLabel,
      fpsLabel: fpsLabel ?? this.fpsLabel,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      addedAt: addedAt ?? this.addedAt,
      transferType: transferType ?? this.transferType,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      availableFormats: availableFormats ?? this.availableFormats,
      selectedFormatId: selectedFormatId ?? this.selectedFormatId,
      commandPreviewLabel: commandPreviewLabel ?? this.commandPreviewLabel,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      authorLabel: authorLabel ?? this.authorLabel,
      selectedFormatSummary:
          selectedFormatSummary ?? this.selectedFormatSummary,
      directDownloadUrl: directDownloadUrl ?? this.directDownloadUrl,
      outputFileName: outputFileName ?? this.outputFileName,
      outputPath: outputPath ?? this.outputPath,
      outputDirectoryPath: outputDirectoryPath ?? this.outputDirectoryPath,
      outputSummaryLabel: outputSummaryLabel ?? this.outputSummaryLabel,
      isYouTubeSource: isYouTubeSource ?? this.isYouTubeSource,
    );
  }
}
