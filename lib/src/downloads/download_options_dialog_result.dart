import 'download_options.dart';

class DownloadOptionsDialogResult {
  final DownloadTransferType transferType;
  final String qualityLabel;
  final String formatLabel;
  final String selectedFormatId;
  final bool startDownload;

  const DownloadOptionsDialogResult({
    required this.transferType,
    required this.qualityLabel,
    required this.formatLabel,
    required this.selectedFormatId,
    required this.startDownload,
  });
}
