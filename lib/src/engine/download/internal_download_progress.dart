class InternalDownloadProgress {
  final int receivedBytes;
  final int? totalBytes;
  final bool isDone;

  const InternalDownloadProgress({
    required this.receivedBytes,
    this.totalBytes,
    this.isDone = false,
  });

  double? get fraction {
    final total = totalBytes;
    if (total == null || total <= 0) return null;
    return receivedBytes / total;
  }

  String get label {
    final received = _formatBytes(receivedBytes);
    final total = totalBytes;
    if (total == null || total <= 0) return received;
    return '$received / ${_formatBytes(total)}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';

    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';

    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';

    final gb = mb / 1024;
    return '${gb.toStringAsFixed(1)} GB';
  }
}
