import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/downloads/download_options.dart';
import 'package:clipflow_downloader/src/downloads/download_preset.dart';

void main() {
  test('fromOptions maps core fields', () {
    const options = DownloadOptions(
      transferType: DownloadTransferType.audio,
      qualityLabel: '720p',
      formatLabel: 'M4A',
    );

    final preset = DownloadPreset.fromOptions(options);

    expect(preset.transferType, DownloadTransferType.audio);
    expect(preset.qualityLabel, '720p');
    expect(preset.formatLabel, 'M4A');
  });

  test('maxHeight maps known values', () {
    const p1080 = DownloadPreset(
      transferType: DownloadTransferType.video,
      qualityLabel: '1080p',
      formatLabel: 'MP4',
    );
    const pBest = DownloadPreset(
      transferType: DownloadTransferType.video,
      qualityLabel: 'Ótima',
      formatLabel: 'MP4',
    );

    expect(p1080.maxHeight, 1080);
    expect(pBest.maxHeight, isNull);
    expect(pBest.isBestQuality, isTrue);
  });

  test('wantsAudioOnly and wantsSubtitles flags', () {
    const audio = DownloadPreset(
      transferType: DownloadTransferType.audio,
      qualityLabel: 'Ótima',
      formatLabel: 'Automático',
    );
    const subtitles = DownloadPreset(
      transferType: DownloadTransferType.subtitles,
      qualityLabel: 'Ótima',
      formatLabel: 'Automático',
    );

    expect(audio.wantsAudioOnly, isTrue);
    expect(audio.wantsVideo, isFalse);
    expect(subtitles.wantsSubtitles, isTrue);
  });

  test('format preferences map flags', () {
    const mp4 = DownloadPreset(
      transferType: DownloadTransferType.video,
      qualityLabel: 'Ótima',
      formatLabel: 'MP4',
    );
    const m4a = DownloadPreset(
      transferType: DownloadTransferType.audio,
      qualityLabel: 'Ótima',
      formatLabel: 'M4A',
    );
    const webm = DownloadPreset(
      transferType: DownloadTransferType.video,
      qualityLabel: 'Ótima',
      formatLabel: 'WEBM',
    );

    expect(mp4.prefersMp4, isTrue);
    expect(m4a.prefersM4a, isTrue);
    expect(webm.prefersWebm, isTrue);
  });
}
