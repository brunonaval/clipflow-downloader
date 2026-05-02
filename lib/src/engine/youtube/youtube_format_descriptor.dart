enum YouTubeFormatKind { video, audio, muxed, subtitles, unknown }

class YouTubeFormatDescriptor {
  final String id;
  final YouTubeFormatKind kind;
  final String mimeType;
  final String extension;
  final String qualityLabel;
  final String bitrateLabel;
  final String sizeLabel;
  final String detailsLabel;
  final bool hasAudio;
  final bool hasVideo;
  final bool isPlayableDescriptor;

  const YouTubeFormatDescriptor({
    required this.id,
    required this.kind,
    required this.mimeType,
    required this.extension,
    required this.qualityLabel,
    required this.bitrateLabel,
    required this.sizeLabel,
    required this.detailsLabel,
    required this.hasAudio,
    required this.hasVideo,
    this.isPlayableDescriptor = true,
  });
}
