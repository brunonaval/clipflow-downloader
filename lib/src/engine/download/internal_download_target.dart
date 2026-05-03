class InternalDownloadTarget {
  final Uri sourceUri;
  final String fileName;
  final bool isDirectFile;

  const InternalDownloadTarget({
    required this.sourceUri,
    required this.fileName,
    required this.isDirectFile,
  });
}
