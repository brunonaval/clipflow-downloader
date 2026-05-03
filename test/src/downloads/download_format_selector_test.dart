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

  test('audio + automático escolhe M4A', () {
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
        formatLabel: 'Automático',
      ),
    );

    expect(selected, '140');
  });

  test('audio + WEBM escolhe WEBM', () {
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
        formatLabel: 'WEBM',
      ),
    );

    expect(selected, '251');
  });

  test('video + MP4 + 1080p escolhe muxed MP4 1080 quando existe', () {
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
        id: '22',
        kind: DownloadFormatKind.video,
        label: 'Vídeo MP4 1080p',
        formatLabel: 'MP4',
        qualityLabel: '1080p',
        detailsLabel: '[muxed] mp4',
      ),
      _f(
        id: '299',
        kind: DownloadFormatKind.video,
        label: 'Vídeo sem áudio',
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

    expect(selected, '22');
  });

  test('video + MP4 + 1080p escolhe videoOnly MP4 se não há muxed', () {
    final formats = [
      _f(
        id: '299',
        kind: DownloadFormatKind.video,
        label: 'Vídeo sem áudio',
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

    expect(selected, '299');
  });

  test('video + MP4 + 720p não escolhe 1080 se existe 720', () {
    final formats = [
      _f(
        id: '22',
        kind: DownloadFormatKind.video,
        label: 'Vídeo MP4 1080p',
        formatLabel: 'MP4',
        qualityLabel: '1080p',
        detailsLabel: '[muxed] mp4',
      ),
      _f(
        id: '18',
        kind: DownloadFormatKind.video,
        label: 'Vídeo MP4 720p',
        formatLabel: 'MP4',
        qualityLabel: '720p',
        detailsLabel: '[muxed] mp4',
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

    expect(selected, '18');
  });

  test('video + automático escolhe muxed MP4', () {
    final formats = [
      _f(
        id: '248',
        kind: DownloadFormatKind.video,
        label: 'Vídeo WEBM 1080p',
        formatLabel: 'WEBM',
        qualityLabel: '1080p',
        detailsLabel: '[video-only] webm',
      ),
      _f(
        id: '22',
        kind: DownloadFormatKind.video,
        label: 'Vídeo MP4 720p',
        formatLabel: 'MP4',
        qualityLabel: '720p',
        detailsLabel: '[muxed] mp4',
      ),
    ];

    final selected = selector.selectRecommendedFormatId(
      formats: formats,
      preset: const DownloadPreset(
        transferType: DownloadTransferType.video,
        qualityLabel: 'Ótima',
        formatLabel: 'Automático',
      ),
    );

    expect(selected, '22');
  });

  test('sem formatos retorna null', () {
    final selected = selector.selectRecommendedFormatId(
      formats: const [],
      preset: const DownloadPreset(
        transferType: DownloadTransferType.video,
        qualityLabel: 'Ótima',
        formatLabel: 'MP4',
      ),
    );

    expect(selected, isNull);
  });
}
