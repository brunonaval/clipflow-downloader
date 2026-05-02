enum DownloadStatus {
  queued,
  analyzing,
  ready,
  downloading,
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
  final DownloadStatus status;
  final double progress;

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
    this.status = DownloadStatus.queued,
    double progress = 0.0,
  }) : progress = progress.clamp(0.0, 1.0);

  String get metadataLabel =>
      '$durationLabel · $sizeLabel · $formatLabel · $qualityLabel · $fpsLabel · $sourceLabel';

  String get statusLabel => switch (status) {
        DownloadStatus.queued => 'Na fila',
        DownloadStatus.analyzing => 'Analisando',
        DownloadStatus.ready => 'Pronto',
        DownloadStatus.downloading => 'Baixando',
        DownloadStatus.completed => 'Concluído',
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
    DownloadStatus? status,
    double? progress,
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
      status: status ?? this.status,
      progress: progress ?? this.progress,
    );
  }
}
