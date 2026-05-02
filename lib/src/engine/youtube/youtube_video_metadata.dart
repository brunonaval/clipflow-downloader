class YouTubeVideoMetadata {
  final String videoId;
  final String title;
  final String durationLabel;
  final String? author;
  final String? thumbnailUrl;
  final bool isLive;
  final bool isPlayable;

  const YouTubeVideoMetadata({
    required this.videoId,
    required this.title,
    required this.durationLabel,
    this.author,
    this.thumbnailUrl,
    this.isLive = false,
    this.isPlayable = true,
  });
}
