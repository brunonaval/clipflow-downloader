import '../../downloads/download_format_option.dart';

class YtDlpAnalysisResult {
  final String title;
  final String durationLabel;
  final List<DownloadFormatOption> formats;
  final String? recommendedFormatId;
  final String? thumbnailUrl;
  final String? authorLabel;

  const YtDlpAnalysisResult({
    required this.title,
    required this.durationLabel,
    required this.formats,
    this.recommendedFormatId,
    this.thumbnailUrl,
    this.authorLabel,
  });
}
