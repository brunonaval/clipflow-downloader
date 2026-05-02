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
    this.qualityLabel = 'Ótima',
    this.formatLabel = 'MP4',
    this.outputFolderLabel = 'Vídeos',
  });

  String get transferLabel => switch (transferType) {
        DownloadTransferType.video => 'Vídeo',
        DownloadTransferType.audio => 'Áudio',
        DownloadTransferType.subtitles => 'Legendas',
        DownloadTransferType.audioTracks => 'Faixas de áudio',
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
