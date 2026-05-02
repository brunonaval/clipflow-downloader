import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/youtube/youtube_page_fetcher.dart';
import 'package:clipflow_downloader/src/engine/youtube/youtube_video_reference.dart';

void main() {
  group('YouTubePageFetcher', () {
    const fetcher = YouTubePageFetcher();

    test('watchUriFor monta URL de watch corretamente', () {
      final reference = YouTubeVideoReference(
        uri: Uri.parse('https://youtu.be/abc123'),
        videoId: 'abc123',
        kind: YouTubeUrlKind.shortLink,
      );

      final uri = fetcher.watchUriFor(reference);
      expect(uri.toString(), 'https://www.youtube.com/watch?v=abc123');
    });

    test('YouTubePageFetchException preserva message e toString', () {
      const error = YouTubePageFetchException('falha');
      expect(error.message, 'falha');
      expect(error.toString(), 'falha');
    });
  });
}
