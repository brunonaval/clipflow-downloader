class YtDlpPlaylistEntry {
  final String id;
  final String title;
  final String url;
  final String? durationLabel;
  final String? thumbnailUrl;
  final String? authorLabel;

  const YtDlpPlaylistEntry({
    required this.id,
    required this.title,
    required this.url,
    this.durationLabel,
    this.thumbnailUrl,
    this.authorLabel,
  });
}

class YtDlpPlaylistResult {
  final String title;
  final String? authorLabel;
  final List<YtDlpPlaylistEntry> entries;

  const YtDlpPlaylistResult({
    required this.title,
    this.authorLabel,
    required this.entries,
  });

  bool get isEmpty => entries.isEmpty;
  int get itemCount => entries.length;
}
