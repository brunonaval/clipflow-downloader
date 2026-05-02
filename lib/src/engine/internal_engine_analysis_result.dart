import '../downloads/download_format_option.dart';

class InternalEngineAnalysisResult {
  final String title;
  final String durationLabel;
  final String sourceLabel;
  final List<DownloadFormatOption> formats;
  final String? recommendedFormatId;
  final bool canDownloadDirectly;
  final Uri? directDownloadUri;

  const InternalEngineAnalysisResult({
    required this.title,
    required this.durationLabel,
    required this.sourceLabel,
    required this.formats,
    required this.recommendedFormatId,
    required this.canDownloadDirectly,
    this.directDownloadUri,
  });
}
