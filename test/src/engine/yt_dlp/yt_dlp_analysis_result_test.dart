import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/downloads/download_format_option.dart';
import 'package:clipflow_downloader/src/engine/yt_dlp/yt_dlp_analysis_result.dart';

void main() {
  test('stores analysis fields', () {
    const formats = [
      DownloadFormatOption(
        id: '22',
        kind: DownloadFormatKind.video,
        label: 'Vídeo MP4 720p',
        formatLabel: 'MP4',
        qualityLabel: '720p',
        sizeLabel: '10 MB',
        detailsLabel: 'yt-dlp format 22',
      ),
    ];

    const result = YtDlpAnalysisResult(
      title: 'Sample',
      durationLabel: '03:21',
      formats: formats,
      recommendedFormatId: '22',
    );

    expect(result.title, 'Sample');
    expect(result.durationLabel, '03:21');
    expect(result.formats, hasLength(1));
    expect(result.recommendedFormatId, '22');
  });
}
