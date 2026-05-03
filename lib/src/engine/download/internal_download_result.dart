enum InternalDownloadStatus { completed, canceled, failed }

class InternalDownloadResult {
  final InternalDownloadStatus status;
  final String message;
  final int receivedBytes;

  const InternalDownloadResult({
    required this.status,
    required this.message,
    required this.receivedBytes,
  });
}
