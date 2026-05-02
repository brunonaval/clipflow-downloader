import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/downloads/download_options.dart';

void main() {
  group('DownloadOptions', () {
    test('has expected defaults', () {
      const options = DownloadOptions();
      expect(options.transferType, DownloadTransferType.video);
      expect(options.qualityLabel, 'Ótima');
      expect(options.formatLabel, 'MP4');
      expect(options.outputFolderLabel, 'Vídeos');
    });

    test('default labels are correct', () {
      const options = DownloadOptions();
      expect(options.transferLabel, 'Vídeo');
      expect(options.toolbarTransferLabel, 'Transferir Vídeo');
      expect(options.toolbarQualityLabel, 'Qualidade Ótima');
      expect(options.toolbarFormatLabel, 'Para MP4');
      expect(options.toolbarOutputFolderLabel, 'Guardar em Vídeos');
    });

    test('labels map correctly for all transfer types', () {
      const audio = DownloadOptions(transferType: DownloadTransferType.audio);
      const subtitles = DownloadOptions(
        transferType: DownloadTransferType.subtitles,
      );
      const tracks = DownloadOptions(
        transferType: DownloadTransferType.audioTracks,
      );

      expect(audio.transferLabel, 'Áudio');
      expect(audio.toolbarTransferLabel, 'Transferir Áudio');
      expect(subtitles.transferLabel, 'Legendas');
      expect(tracks.transferLabel, 'Faixas de áudio');
    });

    test('copyWith updates only provided fields', () {
      const base = DownloadOptions();
      final changedQuality = base.copyWith(qualityLabel: '720p');
      expect(changedQuality.transferType, DownloadTransferType.video);
      expect(changedQuality.qualityLabel, '720p');
      expect(changedQuality.formatLabel, 'MP4');
      expect(changedQuality.outputFolderLabel, 'Vídeos');

      final changedAll = base.copyWith(
        transferType: DownloadTransferType.audio,
        qualityLabel: '1080p',
        formatLabel: 'MP3',
        outputFolderLabel: 'Downloads',
      );
      expect(changedAll.transferType, DownloadTransferType.audio);
      expect(changedAll.qualityLabel, '1080p');
      expect(changedAll.formatLabel, 'MP3');
      expect(changedAll.outputFolderLabel, 'Downloads');
    });
  });
}
