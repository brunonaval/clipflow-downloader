import 'dart:async';
import 'dart:io';

class FfmpegExecutable {
  final String path;
  final String label;

  const FfmpegExecutable({required this.path, required this.label});
}

abstract class FfmpegProcessRunner {
  const FfmpegProcessRunner();

  Future<ProcessResult> run(String executable, List<String> arguments);
}

class DefaultFfmpegProcessRunner extends FfmpegProcessRunner {
  const DefaultFfmpegProcessRunner();

  @override
  Future<ProcessResult> run(String executable, List<String> arguments) {
    return Process.run(executable, arguments);
  }
}

class FfmpegExecutableResolver {
  const FfmpegExecutableResolver({
    FfmpegProcessRunner runner = const DefaultFfmpegProcessRunner(),
  }) : _runner = runner;

  final FfmpegProcessRunner _runner;

  Future<FfmpegExecutable?> resolve() async {
    final candidates = <FfmpegExecutable>[];
    if (Platform.isWindows) {
      candidates.add(
        YtFfmpegExecutablePath.local(
          'tools${Platform.pathSeparator}ffmpeg${Platform.pathSeparator}bin${Platform.pathSeparator}ffmpeg.exe',
          'tools/ffmpeg/bin/ffmpeg.exe',
        ),
      );
      candidates.add(
        YtFfmpegExecutablePath.local(
          'tools${Platform.pathSeparator}ffmpeg.exe',
          'tools/ffmpeg.exe',
        ),
      );
      candidates.add(
        const FfmpegExecutable(path: 'ffmpeg', label: 'ffmpeg (PATH)'),
      );
    } else {
      candidates.add(
        YtFfmpegExecutablePath.local(
          'tools${Platform.pathSeparator}ffmpeg${Platform.pathSeparator}bin${Platform.pathSeparator}ffmpeg',
          'tools/ffmpeg/bin/ffmpeg',
        ),
      );
      candidates.add(
        YtFfmpegExecutablePath.local(
          'tools${Platform.pathSeparator}ffmpeg',
          'tools/ffmpeg',
        ),
      );
      candidates.add(
        const FfmpegExecutable(path: 'ffmpeg', label: 'ffmpeg (PATH)'),
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
      final result = await _runner
          .run(executablePath, const ['-version'])
          .timeout(const Duration(seconds: 5));
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}

class YtFfmpegExecutablePath {
  static FfmpegExecutable local(String relativePath, String label) {
    return FfmpegExecutable(
      path: File(relativePath).absolute.path,
      label: label,
    );
  }
}
