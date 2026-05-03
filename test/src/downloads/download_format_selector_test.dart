import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/downloads/download_format_option.dart';
import 'package:clipflow_downloader/src/downloads/download_format_selector.dart';
import 'package:clipflow_downloader/src/downloads/download_options.dart';
import 'package:clipflow_downloader/src/downloads/download_preset.dart';

DownloadFormatOption _f({
  required String id,
  required DownloadFormatKind kind,
  required String label,
  required String formatLabel,
  required String qualityLabel,
  required String detailsLabel,
}) {
  return DownloadFormatOption(
    id: id,
    kind: kind,
    label: label,
    formatLabel: formatLabel,
    qualityLabel: qualityLabel,
    sizeLabel: '10 MB',
    detailsLabel: detailsLabel,
  );
}

void main() {
  const selector = DownloadFormatSelector();

  test('MP4 + 720p escolhe videoOnly MP4 720p quando existe 720p', () {
    final formats = [
      _f(
        id: '18',
        kind: DownloadFormatKind.video,
        label: 'Vídeo MP4 360p',
        formatLabel: 'MP4',
        qualityLabel: '360p',
        detailsLabel: '[muxed] mp4',
      ),
      _f(
        id: '136',
        kind: DownloadFormatKind.video,
        label: 'Vídeo sem áudio MP4 720p',
        formatLabel: 'MP4',
        qualityLabel: '720p',
        detailsLabel: '[video-only] mp4',
      ),
      _f(
        id: '137',
        kind: DownloadFormatKind.video,
        label: 'Vídeo sem áudio MP4 1080p',
        formatLabel: 'MP4',
        qualityLabel: '1080p',
        detailsLabel: '[video-only] mp4',
      ),
    ];

    final selected = selector.selectRecommendedFormatId(
      formats: formats,
      preset: const DownloadPreset(
        transferType: DownloadTransferType.video,
        qualityLabel: '720p',
        formatLabel: 'MP4',
      ),
    );

    expect(selected, '136');
  });

  test(
    'MP4 + 720p escolhe videoOnly MP4 1080p quando só existem 360p e 1080p',
    () {
      final formats = [
        _f(
          id: '18',
          kind: DownloadFormatKind.video,
          label: 'Vídeo MP4 360p',
          formatLabel: 'MP4',
          qualityLabel: '360p',
          detailsLabel: '[muxed] mp4',
        ),
        _f(
          id: '137',
          kind: DownloadFormatKind.video,
          label: 'Vídeo sem áudio MP4 1080p',
          formatLabel: 'MP4',
          qualityLabel: '1080p',
          detailsLabel: '[video-only] mp4',
        ),
      ];

      final selected = selector.selectRecommendedFormatId(
        formats: formats,
        preset: const DownloadPreset(
          transferType: DownloadTransferType.video,
          qualityLabel: '720p',
          formatLabel: 'MP4',
        ),
      );

      expect(selected, '137');
    },
  );

  test(
    'MP4 + 480p escolhe videoOnly MP4 1080p quando só existem 360p e 1080p',
    () {
      final formats = [
        _f(
          id: '18',
          kind: DownloadFormatKind.video,
          label: 'Vídeo MP4 360p',
          formatLabel: 'MP4',
          qualityLabel: '360p',
          detailsLabel: '[muxed] mp4',
        ),
        _f(
          id: '137',
          kind: DownloadFormatKind.video,
          label: 'Vídeo sem áudio MP4 1080p',
          formatLabel: 'MP4',
          qualityLabel: '1080p',
          detailsLabel: '[video-only] mp4',
        ),
      ];

      final selected = selector.selectRecommendedFormatId(
        formats: formats,
        preset: const DownloadPreset(
          transferType: DownloadTransferType.video,
          qualityLabel: '480p',
          formatLabel: 'MP4',
        ),
      );

      expect(selected, '137');
    },
  );

  test('MP4 + 480p escolhe videoOnly MP4 720p quando existem 360p e 720p', () {
    final formats = [
      _f(
        id: '18',
        kind: DownloadFormatKind.video,
        label: 'Vídeo MP4 360p',
        formatLabel: 'MP4',
        qualityLabel: '360p',
        detailsLabel: '[muxed] mp4',
      ),
      _f(
        id: '136',
        kind: DownloadFormatKind.video,
        label: 'Vídeo sem áudio MP4 720p',
        formatLabel: 'MP4',
        qualityLabel: '720p',
        detailsLabel: '[video-only] mp4',
      ),
    ];

    final selected = selector.selectRecommendedFormatId(
      formats: formats,
      preset: const DownloadPreset(
        transferType: DownloadTransferType.video,
        qualityLabel: '480p',
        formatLabel: 'MP4',
      ),
    );

    expect(selected, '136');
  });

  test('MP4 + 1080p continua escolhendo 1080p', () {
    final formats = [
      _f(
        id: '18',
        kind: DownloadFormatKind.video,
        label: 'Vídeo MP4 360p',
        formatLabel: 'MP4',
        qualityLabel: '360p',
        detailsLabel: '[muxed] mp4',
      ),
      _f(
        id: '137',
        kind: DownloadFormatKind.video,
        label: 'Vídeo sem áudio MP4 1080p',
        formatLabel: 'MP4',
        qualityLabel: '1080p',
        detailsLabel: '[video-only] mp4',
      ),
    ];

    final selected = selector.selectRecommendedFormatId(
      formats: formats,
      preset: const DownloadPreset(
        transferType: DownloadTransferType.video,
        qualityLabel: '1080p',
        formatLabel: 'MP4',
      ),
    );

    expect(selected, '137');
  });

  test('Áudio + M4A não regride', () {
    final formats = [
      _f(
        id: '251',
        kind: DownloadFormatKind.audio,
        label: 'Áudio WEBM',
        formatLabel: 'WEBM',
        qualityLabel: '160k',
        detailsLabel: '[audio-only] webm',
      ),
      _f(
        id: '140',
        kind: DownloadFormatKind.audio,
        label: 'Áudio M4A',
        formatLabel: 'M4A',
        qualityLabel: '128k',
        detailsLabel: '[audio-only] m4a',
      ),
    ];

    final selected = selector.selectRecommendedFormatId(
      formats: formats,
      preset: const DownloadPreset(
        transferType: DownloadTransferType.audio,
        qualityLabel: 'Ótima',
        formatLabel: 'M4A',
      ),
    );

    expect(selected, '140');
  });

  test('WEBM mantém prioridade de container na altura escolhida', () {
    final formats = [
      _f(
        id: '247',
        kind: DownloadFormatKind.video,
        label: 'Vídeo WEBM 720p',
        formatLabel: 'WEBM',
        qualityLabel: '720p',
        detailsLabel: '[muxed] webm',
      ),
      _f(
        id: '136',
        kind: DownloadFormatKind.video,
        label: 'Vídeo sem áudio MP4 720p',
        formatLabel: 'MP4',
        qualityLabel: '720p',
        detailsLabel: '[video-only] mp4',
      ),
    ];

    final selected = selector.selectRecommendedFormatId(
      formats: formats,
      preset: const DownloadPreset(
        transferType: DownloadTransferType.video,
        qualityLabel: '720p',
        formatLabel: 'WEBM',
      ),
    );

    expect(selected, '247');
  });
}
