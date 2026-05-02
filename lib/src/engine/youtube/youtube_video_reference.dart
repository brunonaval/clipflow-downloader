enum YouTubeUrlKind { watch, short, embed, shortLink }

class YouTubeVideoReference {
  final Uri uri;
  final String videoId;
  final YouTubeUrlKind kind;

  const YouTubeVideoReference({
    required this.uri,
    required this.videoId,
    required this.kind,
  });
}
