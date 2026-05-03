import 'download_options.dart';

class DownloadPreset {
  final DownloadTransferType transferType;
  final String qualityLabel;
  final String formatLabel;

  const DownloadPreset({
    required this.transferType,
    required this.qualityLabel,
    required this.formatLabel,
  });

  factory DownloadPreset.fromOptions(DownloadOptions options) {
    return DownloadPreset(
      transferType: options.transferType,
      qualityLabel: options.qualityLabel,
      formatLabel: options.formatLabel,
    );
  }

  bool get wantsVideo => transferType == DownloadTransferType.video;

  bool get wantsAudioOnly =>
      transferType == DownloadTransferType.audio ||
      transferType == DownloadTransferType.audioTracks;

  bool get wantsSubtitles => transferType == DownloadTransferType.subtitles;

  int? get maxHeight {
    return switch (qualityLabel.trim().toLowerCase()) {
      '1080p' => 1080,
      '720p' => 720,
      '480p' => 480,
      '360p' => 360,
      '240p' => 240,
      _ => null,
    };
  }

  bool get prefersMp4 => _normalizedFormat == 'MP4';

  bool get prefersMkv => _normalizedFormat == 'MKV';

  bool get prefersM4a => _normalizedFormat == 'M4A';

  bool get prefersWebm => _normalizedFormat == 'WEBM';

  bool get isBestQuality {
    final normalized = qualityLabel.trim().toLowerCase();
    return normalized == 'ótima' ||
        normalized == 'otima' ||
        normalized == '8k' ||
        normalized == '4k';
  }

  String get _normalizedFormat => formatLabel.trim().toUpperCase();
}
