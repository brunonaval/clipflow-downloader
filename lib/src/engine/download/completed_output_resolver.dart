import 'dart:io';

class CompletedOutputResolver {
  const CompletedOutputResolver();
  static const _preferredExtensions = {'mp4', 'mkv', 'webm', 'm4a'};

  Future<String?> resolve({
    required String? reportedOutputPath,
    required String outputDirectoryPath,
    required String baseName,
    DateTime? startedAt,
  }) async {
    final reported = (reportedOutputPath ?? '').trim();
    if (reported.isNotEmpty &&
        !reported.contains('%(ext)s') &&
        await File(reported).exists()) {
      return reported;
    }

    final directory = Directory(outputDirectoryPath);
    if (!await directory.exists()) return null;

    final normalizedBaseName = baseName.trim().toLowerCase();
    if (normalizedBaseName.isEmpty) return null;

    final threshold = startedAt?.subtract(const Duration(seconds: 5));
    final matches = <_Candidate>[];

    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.isEmpty
          ? ''
          : entity.uri.pathSegments.last;
      final lowerName = name.toLowerCase();
      final startsWithBase =
          lowerName.startsWith('$normalizedBaseName.') ||
          lowerName.startsWith('$normalizedBaseName-') ||
          lowerName.startsWith('$normalizedBaseName (');
      if (!startsWithBase) continue;

      final stat = await entity.stat();
      if (threshold != null && stat.modified.isBefore(threshold)) continue;
      matches.add(
        _Candidate(
          path: entity.path,
          modified: stat.modified,
          rank: _rankCandidate(lowerName, normalizedBaseName),
        ),
      );
    }

    if (matches.isEmpty) return null;
    matches.sort((a, b) {
      if (a.rank != b.rank) return a.rank.compareTo(b.rank);
      return b.modified.compareTo(a.modified);
    });
    return matches.first.path;
  }

  int _rankCandidate(String lowerName, String baseName) {
    if (RegExp(r'\.f\d+\.').hasMatch(lowerName)) return 3;
    if (lowerName.contains('.temp.')) return 3;
    if (lowerName.endsWith('.part')) return 3;

    final extension = lowerName.contains('.')
        ? lowerName.substring(lowerName.lastIndexOf('.') + 1)
        : '';
    if (_preferredExtensions.contains(extension)) {
      if (lowerName == '$baseName.$extension') return 0;
      return 1;
    }
    return 2;
  }
}

class _Candidate {
  final String path;
  final DateTime modified;
  final int rank;

  const _Candidate({
    required this.path,
    required this.modified,
    required this.rank,
  });
}
