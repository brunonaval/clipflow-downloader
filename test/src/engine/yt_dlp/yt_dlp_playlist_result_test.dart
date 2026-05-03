import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/yt_dlp/yt_dlp_playlist_result.dart';

void main() {
  test('builds playlist result and optional fields', () {
    const entry = YtDlpPlaylistEntry(
      id: 'abc123',
      title: 'Video A',
      url: 'https://www.youtube.com/watch?v=abc123',
      durationLabel: '03:20',
      thumbnailUrl: 'https://img.youtube.com/a.jpg',
      authorLabel: 'Canal A',
    );
    const result = YtDlpPlaylistResult(
      title: 'Playlist A',
      authorLabel: 'Autor',
      entries: [entry],
    );

    expect(result.title, 'Playlist A');
    expect(result.authorLabel, 'Autor');
    expect(result.itemCount, 1);
    expect(result.isEmpty, isFalse);
    expect(result.entries.first.thumbnailUrl, isNotNull);
  });

  test('empty playlist reports isEmpty true', () {
    const result = YtDlpPlaylistResult(title: 'Vazia', entries: []);
    expect(result.isEmpty, isTrue);
    expect(result.itemCount, 0);
  });
}
