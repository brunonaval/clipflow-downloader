import 'dart:io';

class CompletedOutputResolver {
  const CompletedOutputResolver();

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
      final startsWithBase = lowerName.startsWith(normalizedBaseName);
      final containsBase = lowerName.contains(normalizedBaseName);
      if (!startsWithBase && !containsBase) continue;

      final stat = await entity.stat();
      if (threshold != null && stat.modified.isBefore(threshold)) continue;
      matches.add(_Candidate(path: entity.path, modified: stat.modified));
    }

    if (matches.isEmpty) return null;
    matches.sort((a, b) => b.modified.compareTo(a.modified));
    return matches.first.path;
  }
}

class _Candidate {
  final String path;
  final DateTime modified;

  const _Candidate({required this.path, required this.modified});
}
