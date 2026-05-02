class InternalDownloadRequest {
  final Uri sourceUri;
  final String fileName;
  final int? expectedBytes;

  const InternalDownloadRequest({
    required this.sourceUri,
    required this.fileName,
    this.expectedBytes,
  });

  bool get isHttpOrHttps =>
      sourceUri.scheme == 'http' || sourceUri.scheme == 'https';
}
