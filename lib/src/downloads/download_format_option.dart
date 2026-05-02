enum DownloadFormatKind { video, audio, subtitles }

class DownloadFormatOption {
  final String id;
  final DownloadFormatKind kind;
  final String label;
  final String formatLabel;
  final String qualityLabel;
  final String sizeLabel;
  final String detailsLabel;
  final bool isRecommended;

  const DownloadFormatOption({
    required this.id,
    required this.kind,
    required this.label,
    required this.formatLabel,
    required this.qualityLabel,
    required this.sizeLabel,
    required this.detailsLabel,
    this.isRecommended = false,
  });

  String get displayLabel =>
      '$label · $formatLabel · $qualityLabel · $sizeLabel';
}
