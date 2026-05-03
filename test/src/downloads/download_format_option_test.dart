import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/downloads/download_format_option.dart';

void main() {
  group('DownloadFormatOption', () {
    test('displayLabel contains label, format, quality and size', () {
      const option = DownloadFormatOption(
        id: 'video-mp4-1080p',
        kind: DownloadFormatKind.video,
        label: 'Vídeo MP4 1080p',
        formatLabel: 'MP4',
        qualityLabel: '1080p',
        sizeLabel: '24 MB',
        detailsLabel: 'Vídeo com áudio em MP4',
      );

      expect(option.displayLabel, contains('Vídeo MP4 1080p'));
      expect(option.displayLabel, contains('MP4'));
      expect(option.displayLabel, contains('1080p'));
      expect(option.displayLabel, contains('24 MB'));
    });

    test('isRecommended defaults to false', () {
      const option = DownloadFormatOption(
        id: 'audio-m4a',
        kind: DownloadFormatKind.audio,
        label: 'Áudio M4A',
        formatLabel: 'M4A',
        qualityLabel: 'Áudio',
        sizeLabel: '5 MB',
        detailsLabel: 'Somente áudio',
      );

      expect(option.isRecommended, isFalse);
    });

    test('kind is preserved', () {
      const option = DownloadFormatOption(
        id: 'subtitles-srt',
        kind: DownloadFormatKind.subtitles,
        label: 'Legendas SRT',
        formatLabel: 'SRT',
        qualityLabel: 'Texto',
        sizeLabel: '120 KB',
        detailsLabel: 'Legendas mockadas',
      );

      expect(option.kind, DownloadFormatKind.subtitles);
    });
  });
}
