enum DownloadTransferType {
  video,
  audio,
  subtitles,
  audioTracks,
}

class DownloadOptions {
  final DownloadTransferType transferType;
  final String qualityLabel;
  final String formatLabel;
  final String outputFolderLabel;

  const DownloadOptions({
    this.transferType = DownloadTransferType.video,
    this.qualityLabel = '\u00d3tima',
    this.formatLabel = 'MP4',
    this.outputFolderLabel = 'V\u00eddeos',
  });

  String get transferLabel => switch (transferType) {
        DownloadTransferType.video => 'V\u00eddeo',
        DownloadTransferType.audio => '\u00c1udio',
        DownloadTransferType.subtitles => 'Legendas',
        DownloadTransferType.audioTracks => 'Faixas de \u00e1udio',
      };

  String get toolbarTransferLabel => 'Transferir $transferLabel';

  String get toolbarQualityLabel => 'Qualidade $qualityLabel';

  String get toolbarFormatLabel => 'Para $formatLabel';

  String get toolbarOutputFolderLabel => 'Guardar em $outputFolderLabel';

  DownloadOptions copyWith({
    DownloadTransferType? transferType,
    String? qualityLabel,
    String? formatLabel,
    String? outputFolderLabel,
  }) {
    return DownloadOptions(
      transferType: transferType ?? this.transferType,
      qualityLabel: qualityLabel ?? this.qualityLabel,
      formatLabel: formatLabel ?? this.formatLabel,
      outputFolderLabel: outputFolderLabel ?? this.outputFolderLabel,
    );
  }
}
