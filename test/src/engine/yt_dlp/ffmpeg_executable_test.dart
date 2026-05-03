import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/yt_dlp/ffmpeg_executable.dart';

class _FakeFfmpegRunnerSuccess extends FfmpegProcessRunner {
  const _FakeFfmpegRunnerSuccess();

  @override
  Future<ProcessResult> run(String executable, List<String> arguments) async {
    return ProcessResult(1, 0, 'ffmpeg version fake', '');
  }
}

class _FakeFfmpegRunnerFailure extends FfmpegProcessRunner {
  const _FakeFfmpegRunnerFailure();

  @override
  Future<ProcessResult> run(String executable, List<String> arguments) async {
    return ProcessResult(1, 1, '', 'not found');
  }
}

void main() {
  test('FfmpegExecutable preserves path and label', () {
    const executable = FfmpegExecutable(path: '/tmp/ffmpeg', label: 'fake');
    expect(executable.path, '/tmp/ffmpeg');
    expect(executable.label, 'fake');
  });

  test('resolver returns null when all candidates fail', () async {
    final resolver = FfmpegExecutableResolver(
      runner: const _FakeFfmpegRunnerFailure(),
    );

    final executable = await resolver.resolve();
    expect(executable, isNull);
  });

  test('resolver returns executable when candidate succeeds', () async {
    final resolver = FfmpegExecutableResolver(
      runner: const _FakeFfmpegRunnerSuccess(),
    );

    final executable = await resolver.resolve();
    expect(executable, isNotNull);
  });
}
