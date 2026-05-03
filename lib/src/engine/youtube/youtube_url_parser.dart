import 'youtube_video_reference.dart';

class YouTubeUrlParser {
  const YouTubeUrlParser();

  YouTubeVideoReference? parse(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) return null;

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;

    final host = uri.host.toLowerCase();
    if (_isYouTubeHost(host)) {
      return _parseYoutubeCom(uri);
    }
    if (host == 'youtu.be') {
      return _parseShortLink(uri);
    }

    return null;
  }

  bool isYouTubeUrl(String rawUrl) => parse(rawUrl) != null;

  bool _isYouTubeHost(String host) {
    return host == 'youtube.com' ||
        host == 'www.youtube.com' ||
        host == 'm.youtube.com';
  }

  YouTubeVideoReference? _parseYoutubeCom(Uri uri) {
    final segments = uri.pathSegments.where((segment) {
      return segment.trim().isNotEmpty;
    }).toList();

    if (segments.isEmpty) {
      return null;
    }

    final first = segments.first.toLowerCase();
    if (first == 'watch') {
      final videoId = uri.queryParameters['v']?.trim() ?? '';
      if (videoId.isEmpty) return null;
      return YouTubeVideoReference(
        uri: uri,
        videoId: videoId,
        kind: YouTubeUrlKind.watch,
      );
    }

    if (first == 'shorts' && segments.length >= 2) {
      final videoId = segments[1].trim();
      if (videoId.isEmpty) return null;
      return YouTubeVideoReference(
        uri: uri,
        videoId: videoId,
        kind: YouTubeUrlKind.short,
      );
    }

    if (first == 'embed' && segments.length >= 2) {
      final videoId = segments[1].trim();
      if (videoId.isEmpty) return null;
      return YouTubeVideoReference(
        uri: uri,
        videoId: videoId,
        kind: YouTubeUrlKind.embed,
      );
    }

    return null;
  }

  YouTubeVideoReference? _parseShortLink(Uri uri) {
    final segments = uri.pathSegments.where((segment) {
      return segment.trim().isNotEmpty;
    }).toList();
    if (segments.isEmpty) return null;

    final videoId = segments.first.trim();
    if (videoId.isEmpty) return null;

    return YouTubeVideoReference(
      uri: uri,
      videoId: videoId,
      kind: YouTubeUrlKind.shortLink,
    );
  }
}
