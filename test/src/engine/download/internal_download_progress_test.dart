import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/download/internal_download_progress.dart';

void main() {
  group('InternalDownloadProgress', () {
    test('fraction retorna null sem totalBytes', () {
      const progress = InternalDownloadProgress(receivedBytes: 1200);
      expect(progress.fraction, isNull);
    });

    test('fraction retorna null com totalBytes <= 0', () {
      const progress = InternalDownloadProgress(
        receivedBytes: 1200,
        totalBytes: 0,
      );
      expect(progress.fraction, isNull);
    });

    test('fraction calcula valor quando totalBytes valido', () {
      const progress = InternalDownloadProgress(
        receivedBytes: 1024,
        totalBytes: 2048,
      );
      expect(progress.fraction, 0.5);
    });

    test('label mostra recebido e total quando total existe', () {
      const progress = InternalDownloadProgress(
        receivedBytes: 1024 * 1024,
        totalBytes: 4 * 1024 * 1024,
      );
      expect(progress.label, '1.0 MB / 4.0 MB');
    });

    test('label mostra apenas recebido quando total nao existe', () {
      const progress = InternalDownloadProgress(receivedBytes: 1024 * 1024);
      expect(progress.label, '1.0 MB');
    });
  });
}
