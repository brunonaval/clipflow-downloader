import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'youtube_video_reference.dart';

class YouTubePageFetchException implements Exception {
  final String message;
  const YouTubePageFetchException(this.message);

  @override
  String toString() => message;
}

class YouTubePageFetcher {
  const YouTubePageFetcher();

  Uri watchUriFor(YouTubeVideoReference reference) {
    return Uri.https('www.youtube.com', '/watch', {'v': reference.videoId});
  }

  Future<String> fetchWatchHtml(YouTubeVideoReference reference) async {
    final uri = watchUriFor(reference);
    final client = HttpClient();

    try {
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 8));
      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );

      if (response.statusCode != HttpStatus.ok) {
        throw YouTubePageFetchException(
          'Falha ao carregar página do YouTube (HTTP ${response.statusCode})',
        );
      }

      const maxBytes = 3 * 1024 * 1024;
      final buffer = BytesBuilder(copy: false);

      await for (final chunk in response.timeout(const Duration(seconds: 8))) {
        buffer.add(chunk);
        if (buffer.length > maxBytes) {
          throw const YouTubePageFetchException(
            'Página do YouTube excedeu o limite de leitura',
          );
        }
      }

      return utf8.decode(buffer.takeBytes(), allowMalformed: true);
    } on TimeoutException {
      throw const YouTubePageFetchException(
        'Tempo limite ao buscar página do YouTube',
      );
    } on SocketException {
      throw const YouTubePageFetchException(
        'Falha de rede ao buscar página do YouTube',
      );
    } on HttpException catch (e) {
      throw YouTubePageFetchException(
        'Erro HTTP ao buscar YouTube: ${e.message}',
      );
    } finally {
      client.close(force: true);
    }
  }
}
