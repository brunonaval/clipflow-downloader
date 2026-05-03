import 'dart:io';

class YtDlpOutputNamePlanner {
  const YtDlpOutputNamePlanner();

  static const _extensions = <String>{
    '.mp4',
    '.mkv',
    '.webm',
    '.m4a',
    '.mp3',
    '.opus',
    '.part',
  };

  Future<String> uniqueBaseName({
    required Directory directory,
    required String requestedBaseName,
  }) async {
    final base = requestedBaseName.trim();
    if (base.isEmpty) return 'youtube-video';
    if (!await _hasCollision(directory, base)) return base;

    var index = 1;
    while (true) {
      final candidate = '$base ($index)';
      if (!await _hasCollision(directory, candidate)) return candidate;
      index += 1;
    }
  }

  Future<bool> _hasCollision(Directory directory, String base) async {
    if (!await directory.exists()) return false;
    final lowerBase = base.toLowerCase();

    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.isEmpty
          ? ''
          : entity.uri.pathSegments.last.toLowerCase();
      if (_isExactKnownOutput(name, lowerBase)) return true;
      if (name.startsWith('$lowerBase.f')) return true;
      if (name.startsWith('$lowerBase.temp.')) return true;
      if (name == '$lowerBase.part') return true;
    }
    return false;
  }

  bool _isExactKnownOutput(String lowerName, String lowerBase) {
    for (final extension in _extensions) {
      if (lowerName == '$lowerBase$extension') return true;
    }
    return false;
  }
}
