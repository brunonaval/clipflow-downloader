class YouTubePlaylistUrlParser {
  const YouTubePlaylistUrlParser();

  bool isPlaylistUrl(String rawUrl) => playlistIdFrom(rawUrl) != null;

  String? playlistIdFrom(String rawUrl) {
    final safe = rawUrl.trim();
    if (safe.isEmpty) return null;
    final uri = Uri.tryParse(safe);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    final isYouTubeHost =
        host == 'youtube.com' ||
        host == 'www.youtube.com' ||
        host == 'm.youtube.com';
    if (!isYouTubeHost) return null;
    if (uri.path.toLowerCase() != '/playlist') return null;

    final listId = uri.queryParameters['list']?.trim();
    if (listId == null || listId.isEmpty) return null;
    return listId;
  }
}
