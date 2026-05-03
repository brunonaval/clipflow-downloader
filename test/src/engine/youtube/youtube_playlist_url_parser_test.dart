import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/youtube/youtube_playlist_url_parser.dart';

void main() {
  const parser = YouTubePlaylistUrlParser();

  test('detects playlist endpoint with list', () {
    expect(
      parser.isPlaylistUrl('https://www.youtube.com/playlist?list=PL123'),
      isTrue,
    );
    expect(
      parser.playlistIdFrom('https://www.youtube.com/playlist?list=PL123'),
      'PL123',
    );
  });

  test('detects watch endpoint with list parameter', () {
    expect(
      parser.isPlaylistUrl('https://m.youtube.com/watch?v=abc&list=PL999'),
      isTrue,
    );
    expect(
      parser.playlistIdFrom('https://youtube.com/watch?v=abc&list=PL999'),
      'PL999',
    );
  });

  test('video url without list is not playlist', () {
    expect(parser.isPlaylistUrl('https://youtube.com/watch?v=abc'), isFalse);
    expect(parser.playlistIdFrom('https://youtube.com/watch?v=abc'), isNull);
  });

  test('invalid url is not playlist', () {
    expect(parser.isPlaylistUrl('not-a-url'), isFalse);
    expect(parser.playlistIdFrom('not-a-url'), isNull);
  });
}
