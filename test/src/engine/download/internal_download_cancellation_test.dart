import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/download/internal_download_cancellation.dart';

void main() {
  test('InternalDownloadCancellation inicia nao cancelado e cancela', () {
    final cancellation = InternalDownloadCancellation();
    expect(cancellation.isCanceled, isFalse);

    cancellation.cancel();

    expect(cancellation.isCanceled, isTrue);
  });
}
