import 'dart:convert';

import 'youtube_video_metadata.dart';

class YouTubeHtmlMetadataParser {
  const YouTubeHtmlMetadataParser();

  YouTubeVideoMetadata? parse({
    required String html,
    required String videoId,
  }) {
    final playerJson =
        _extractInitialPlayerResponseJson(html) ??
        _extractInitialPlayerResponsePropertyJson(html);

    String? title;
    String durationLabel = '--:--';
    String? author;
    String? thumbnailUrl;
    bool isLive = false;
    bool isPlayable = true;

    if (playerJson != null) {
      try {
        final decoded = jsonDecode(playerJson);
        if (decoded is Map<String, dynamic>) {
          final videoDetails = _asMap(decoded['videoDetails']);
          final playability = _asMap(decoded['playabilityStatus']);

          final rawTitle = videoDetails?['title']?.toString().trim();
          if (rawTitle != null && rawTitle.isNotEmpty) {
            title = rawTitle;
          }

          final rawLength = videoDetails?['lengthSeconds']?.toString();
          durationLabel = _formatDuration(rawLength) ?? durationLabel;

          final rawAuthor = videoDetails?['author']?.toString().trim();
          if (rawAuthor != null && rawAuthor.isNotEmpty) {
            author = rawAuthor;
          }

          thumbnailUrl = _extractThumbnailUrl(videoDetails?['thumbnail']);
          isLive = _asBool(videoDetails?['isLiveContent']);

          final status = playability?['status']?.toString().toUpperCase() ?? '';
          if (status == 'LOGIN_REQUIRED' ||
              status == 'UNPLAYABLE' ||
              status == 'ERROR' ||
              status == 'AGE_CHECK_REQUIRED') {
            isPlayable = false;
          }
        }
      } catch (_) {
        // Fallbacks below handle malformed JSON.
      }
    }

    title ??=
        _htmlMeta(html, property: 'og:title') ??
        _htmlMeta(html, name: 'title') ??
        _htmlTitle(html);

    if (title == null || title.trim().isEmpty) return null;
    final cleanTitle = _cleanTitle(title.trim());
    if (cleanTitle.isEmpty) return null;

    return YouTubeVideoMetadata(
      videoId: videoId,
      title: cleanTitle,
      durationLabel: durationLabel,
      author: author,
      thumbnailUrl: thumbnailUrl,
      isLive: isLive,
      isPlayable: isPlayable,
    );
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
    if (startIndex < 0 || startIndex >= text.length || text[startIndex] != '{') {
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
        final key = entry.key.toString();
        result[key] = entry.value;
      }
      return result;
    }
    return null;
  }

  bool _asBool(Object? value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  String? _extractThumbnailUrl(Object? thumbnailValue) {
    final thumbnailMap = _asMap(thumbnailValue);
    final thumbs = thumbnailMap?['thumbnails'];
    if (thumbs is List && thumbs.isNotEmpty) {
      for (var i = thumbs.length - 1; i >= 0; i--) {
        final candidate = _asMap(thumbs[i]);
        final url = candidate?['url']?.toString().trim();
        if (url != null && url.isNotEmpty) return url;
      }
    }
    return null;
  }

  String? _formatDuration(String? secondsText) {
    if (secondsText == null) return null;
    final seconds = int.tryParse(secondsText);
    if (seconds == null || seconds < 0) return null;

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String? _htmlMeta(String html, {String? property, String? name}) {
    final attrKey = property != null ? 'property' : 'name';
    final attrValue = property ?? name;
    if (attrValue == null) return null;

    final regex = RegExp(
      "<meta[^>]*$attrKey=['\"]${RegExp.escape(attrValue)}['\"][^>]*content=['\"]([^'\"]+)['\"][^>]*>",
      caseSensitive: false,
    );
    final match = regex.firstMatch(html);
    if (match == null) return null;
    final content = match.group(1)?.trim();
    if (content == null || content.isEmpty) return null;
    return _decodeHtmlEntities(content);
  }

  String? _htmlTitle(String html) {
    final regex = RegExp(r'<title[^>]*>(.*?)</title>', caseSensitive: false);
    final match = regex.firstMatch(html);
    if (match == null) return null;
    final value = match.group(1)?.trim();
    if (value == null || value.isEmpty) return null;
    return _decodeHtmlEntities(value);
  }

  String _cleanTitle(String value) {
    if (value.endsWith(' - YouTube')) {
      return value.substring(0, value.length - ' - YouTube'.length).trim();
    }
    return value;
  }

  String _decodeHtmlEntities(String value) {
    return value
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }
}
