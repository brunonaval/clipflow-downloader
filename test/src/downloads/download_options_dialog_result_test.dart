import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/downloads/download_options.dart';
import 'package:clipflow_downloader/src/downloads/download_options_dialog_result.dart';

void main() {
  test('builds with required fields', () {
    const result = DownloadOptionsDialogResult(
      transferType: DownloadTransferType.video,
      qualityLabel: '1080p',
      formatLabel: 'MP4',
      selectedFormatId: '137',
      startDownload: true,
    );

    expect(result.transferType, DownloadTransferType.video);
    expect(result.qualityLabel, '1080p');
    expect(result.formatLabel, 'MP4');
    expect(result.selectedFormatId, '137');
    expect(result.startDownload, isTrue);
  });
}
