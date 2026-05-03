enum InternalDownloadStatus { completed, canceled, failed }

class InternalDownloadResult {
  final InternalDownloadStatus status;
  final String message;
  final int receivedBytes;
  final String? outputPath;

  const InternalDownloadResult({
    required this.status,
    required this.message,
    required this.receivedBytes,
    this.outputPath,
  });
}
