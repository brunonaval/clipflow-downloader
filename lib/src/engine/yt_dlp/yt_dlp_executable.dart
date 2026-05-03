import 'dart:async';
import 'dart:io';

class YtDlpExecutable {
  final String path;
  final String label;

  const YtDlpExecutable({required this.path, required this.label});
}

class YtDlpExecutableResolver {
  const YtDlpExecutableResolver();

  Future<YtDlpExecutable?> resolve() async {
    final candidates = <YtDlpExecutable>[];
    if (Platform.isWindows) {
      final local = File(
        'tools${Platform.pathSeparator}yt-dlp.exe',
      ).absolute.path;
      candidates.add(YtDlpExecutable(path: local, label: 'tools/yt-dlp.exe'));
      candidates.add(
        const YtDlpExecutable(path: 'yt-dlp', label: 'yt-dlp (PATH)'),
      );
    } else {
      final local = File('tools${Platform.pathSeparator}yt-dlp').absolute.path;
      candidates.add(YtDlpExecutable(path: local, label: './tools/yt-dlp'));
      candidates.add(
        const YtDlpExecutable(path: 'yt-dlp', label: 'yt-dlp (PATH)'),
      );
    }

    for (final candidate in candidates) {
      if (await _isUsable(candidate.path)) {
        return candidate;
      }
    }
    return null;
  }

  Future<bool> _isUsable(String executablePath) async {
    try {
      final result = await Process.run(executablePath, const [
        '--version',
      ]).timeout(const Duration(seconds: 5));
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
