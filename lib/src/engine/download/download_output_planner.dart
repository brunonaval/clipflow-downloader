import 'dart:io';

class DownloadOutputPlan {
  final Directory directory;
  final File file;
  final String fileName;

  const DownloadOutputPlan({
    required this.directory,
    required this.file,
    required this.fileName,
  });
}

class DownloadOutputPlanner {
  const DownloadOutputPlanner();

  Directory defaultDownloadDirectory() {
    final env = Platform.environment;
    String? basePath;

    if (Platform.isWindows) {
      basePath = env['USERPROFILE'];
    } else {
      basePath = env['HOME'];
    }

    if (basePath != null && basePath.trim().isNotEmpty) {
      return Directory(
        '$basePath${Platform.pathSeparator}Downloads${Platform.pathSeparator}ClipFlow',
      );
    }

    return Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}ClipFlow',
    );
  }

  Future<DownloadOutputPlan> plan({
    required String requestedFileName,
    Directory? baseDirectory,
  }) async {
    final directory = baseDirectory ?? defaultDownloadDirectory();
    await directory.create(recursive: true);

    final safeRequested = _sanitizeFileName(requestedFileName);
    final uniqueFileName = await _nextAvailableFileName(
      directory,
      safeRequested,
    );
    final file = File(
      '${directory.path}${Platform.pathSeparator}$uniqueFileName',
    );

    return DownloadOutputPlan(
      directory: directory,
      file: file,
      fileName: uniqueFileName,
    );
  }

  String _sanitizeFileName(String requestedFileName) {
    final cleaned = requestedFileName
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim();

    final fallback = cleaned.isEmpty ? 'clipflow-download.bin' : cleaned;
    if (fallback.length <= 120) return fallback;

    final dot = fallback.lastIndexOf('.');
    if (dot > 0 && dot < fallback.length - 1) {
      final ext = fallback.substring(dot);
      final base = fallback.substring(0, dot);
      final maxBaseLen = 120 - ext.length;
      if (maxBaseLen > 0) {
        return '${base.substring(0, maxBaseLen)}$ext';
      }
    }

    return fallback.substring(0, 120);
  }

  Future<String> _nextAvailableFileName(
    Directory directory,
    String fileName,
  ) async {
    final dot = fileName.lastIndexOf('.');
    final hasExt = dot > 0 && dot < fileName.length - 1;
    final base = hasExt ? fileName.substring(0, dot) : fileName;
    final ext = hasExt ? fileName.substring(dot) : '';

    var candidate = fileName;
    var index = 1;

    while (await File(
      '${directory.path}${Platform.pathSeparator}$candidate',
    ).exists()) {
      candidate = '$base ($index)$ext';
      if (candidate.length > 120) {
        final maxBaseLength = 120 - ' ($index)$ext'.length;
        final trimmedBase = maxBaseLength > 0
            ? base.substring(
                0,
                base.length < maxBaseLength ? base.length : maxBaseLength,
              )
            : 'clipflow-download';
        candidate = '$trimmedBase ($index)$ext';
      }
      index += 1;
    }

    return candidate;
  }
}
