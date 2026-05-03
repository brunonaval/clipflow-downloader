class YouTubePlaylistUrlParser {
  const YouTubePlaylistUrlParser();

  bool isPlaylistUrl(String rawUrl) => playlistIdFrom(rawUrl) != null;

  bool isWatchUrlWithPlaylist(String rawUrl) {
    final uri = _parseYouTubeUri(rawUrl);
    if (uri == null) return false;
    if (uri.path.toLowerCase() != '/watch') return false;
    final videoId = uri.queryParameters['v']?.trim();
    final listId = uri.queryParameters['list']?.trim();
    if (videoId == null || videoId.isEmpty) return false;
    if (listId == null || listId.isEmpty) return false;
    return true;
  }

  String? playlistUrlFromWatchUrl(String rawUrl) {
    final uri = _parseYouTubeUri(rawUrl);
    if (uri == null) return null;
    if (uri.path.toLowerCase() != '/watch') return null;
    final listId = uri.queryParameters['list']?.trim();
    if (listId == null || listId.isEmpty) return null;
    return 'https://www.youtube.com/playlist?list=$listId';
  }

  String? playlistIdFrom(String rawUrl) {
    final uri = _parseYouTubeUri(rawUrl);
    if (uri == null) return null;
    if (uri.path.toLowerCase() != '/playlist') return null;

    final listId = uri.queryParameters['list']?.trim();
    if (listId == null || listId.isEmpty) return null;
    return listId;
  }

  Uri? _parseYouTubeUri(String rawUrl) {
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
    return uri;
  }
}
