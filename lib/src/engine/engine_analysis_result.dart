import '../downloads/download_format_option.dart';

class EngineAnalysisResult {
  final String title;
  final String durationLabel;
  final String sourceLabel;
  final List<DownloadFormatOption> formats;
  final String? recommendedFormatId;

  const EngineAnalysisResult({
    required this.title,
    required this.durationLabel,
    required this.sourceLabel,
    required this.formats,
    this.recommendedFormatId,
  });
}
