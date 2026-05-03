import 'dart:convert';

import 'youtube_direct_media_failure.dart';

class YouTubeDirectMediaReference {
  final String formatId;
  final Uri mediaUri;
  final String fileExtension;
  final String safeHostLabel;

  const YouTubeDirectMediaReference({
    required this.formatId,
    required this.mediaUri,
    required this.fileExtension,
    required this.safeHostLabel,
  });
}

class YouTubeDirectMediaLocator {
  const YouTubeDirectMediaLocator();

  YouTubeDirectMediaReference? locateDirectMedia({
    required String html,
    required String formatId,
  }) {
    final result = lookupDirectMedia(html: html, formatId: formatId);
    return result.reference;
  }

  YouTubeDirectMediaLookupResult lookupDirectMedia({
    required String html,
    required String formatId,
  }) {
    final playerJson =
        _extractInitialPlayerResponseJson(html) ??
        _extractInitialPlayerResponsePropertyJson(html);
    if (playerJson == null) {
      return const YouTubeDirectMediaLookupResult.failure(
        YouTubeDirectMediaFailure(
          reason: YouTubeDirectMediaFailureReason.unsupported,
          message: 'Player do YouTube não suportado pelo motor interno.',
        ),
      );
    }

    try {
      final decoded = jsonDecode(playerJson);
      if (decoded is! Map<String, dynamic>) {
        return const YouTubeDirectMediaLookupResult.failure(
          YouTubeDirectMediaFailure(
            reason: YouTubeDirectMediaFailureReason.unsupported,
            message: 'Player do YouTube não suportado pelo motor interno.',
          ),
        );
      }

      final streamingData = _asMap(decoded['streamingData']);
      if (streamingData == null) {
        return const YouTubeDirectMediaLookupResult.failure(
          YouTubeDirectMediaFailure(
            reason: YouTubeDirectMediaFailureReason.unsupported,
            message: 'Player do YouTube não suportado pelo motor interno.',
          ),
        );
      }

      final format =
          _findFormat(streamingData['formats'], formatId) ??
          _findFormat(streamingData['adaptiveFormats'], formatId);
      if (format == null) {
        return const YouTubeDirectMediaLookupResult.failure(
          YouTubeDirectMediaFailure(
            reason: YouTubeDirectMediaFailureReason.formatNotFound,
            message: 'Formato não encontrado no player.',
          ),
        );
      }

      if (format.containsKey('signatureCipher') ||
          format.containsKey('cipher')) {
        return const YouTubeDirectMediaLookupResult.failure(
          YouTubeDirectMediaFailure(
            reason: YouTubeDirectMediaFailureReason.requiresSignature,
            message: 'Formato exige assinatura; escolha outro formato.',
          ),
        );
      }

      final rawUrl = format['url']?.toString().trim();
      if (rawUrl == null || rawUrl.isEmpty) {
        return const YouTubeDirectMediaLookupResult.failure(
          YouTubeDirectMediaFailure(
            reason: YouTubeDirectMediaFailureReason.noDirectUrl,
            message: 'Formato sem URL direta disponível.',
          ),
        );
      }

      final mediaUri = Uri.tryParse(rawUrl);
      if (mediaUri == null ||
          !(mediaUri.scheme == 'http' || mediaUri.scheme == 'https')) {
        return const YouTubeDirectMediaLookupResult.failure(
          YouTubeDirectMediaFailure(
            reason: YouTubeDirectMediaFailureReason.invalidUrl,
            message: 'URL de mídia inválida.',
          ),
        );
      }

      final mimeType = format['mimeType']?.toString() ?? '';
      final ext = _extensionFromMimeType(mimeType);

      return YouTubeDirectMediaLookupResult.reference(
        YouTubeDirectMediaReference(
          formatId: formatId,
          mediaUri: mediaUri,
          fileExtension: ext,
          safeHostLabel: mediaUri.host,
        ),
      );
    } catch (_) {
      return const YouTubeDirectMediaLookupResult.failure(
        YouTubeDirectMediaFailure(
          reason: YouTubeDirectMediaFailureReason.unsupported,
          message: 'Player do YouTube não suportado pelo motor interno.',
        ),
      );
    }
  }

  Map<String, dynamic>? _findFormat(Object? value, String formatId) {
    if (value is! List) return null;
    for (final item in value) {
      final map = _asMap(item);
      if (map == null) continue;
      final itag = map['itag']?.toString();
      if (itag == formatId) return map;
    }
    return null;
  }

  String _extensionFromMimeType(String mimeType) {
    final lower = mimeType.toLowerCase();
    if (lower.startsWith('video/mp4')) return 'mp4';
    if (lower.startsWith('audio/mp4')) return 'm4a';
    if (lower.startsWith('video/webm') || lower.startsWith('audio/webm')) {
      return 'webm';
    }
    return 'bin';
  }

  String? _extractInitialPlayerResponseJson(String html) {
    const marker = 'var ytInitialPlayerResponse =';
    final markerIndex = html.indexOf(marker);
    if (markerIndex < 0) return null;

    final braceStart = html.indexOf('{', markerIndex + marker.length);
    if (braceStart < 0) return null;
    return _extractBalancedJsonObject(html, braceStart);
  }

  String? _extractInitialPlayerResponsePropertyJson(String html) {
    const marker = '"ytInitialPlayerResponse":';
    final markerIndex = html.indexOf(marker);
    if (markerIndex < 0) return null;

    final braceStart = html.indexOf('{', markerIndex + marker.length);
    if (braceStart < 0) return null;
    return _extractBalancedJsonObject(html, braceStart);
  }

  String? _extractBalancedJsonObject(String text, int startIndex) {
    if (startIndex < 0 ||
        startIndex >= text.length ||
        text[startIndex] != '{') {
      return null;
    }

    var depth = 0;
    var inString = false;
    var escaped = false;

    for (var i = startIndex; i < text.length; i++) {
      final char = text[i];

      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (char == r'\') {
          escaped = true;
        } else if (char == '"') {
          inString = false;
        }
        continue;
      }

      if (char == '"') {
        inString = true;
        continue;
      }

      if (char == '{') {
        depth += 1;
      } else if (char == '}') {
        depth -= 1;
        if (depth == 0) {
          return text.substring(startIndex, i + 1);
        }
      }
    }

    return null;
  }

  Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      final result = <String, dynamic>{};
      for (final entry in value.entries) {
        result[entry.key.toString()] = entry.value;
      }
      return result;
    }
    return null;
  }
}
