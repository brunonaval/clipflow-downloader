import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/yt_dlp/yt_dlp_engine_service.dart';
import 'package:clipflow_downloader/src/engine/yt_dlp/yt_dlp_executable.dart';

class _FakeResolverAvailable extends YtDlpExecutableResolver {
  const _FakeResolverAvailable();

  @override
  Future<YtDlpExecutable?> resolve() async {
    return const YtDlpExecutable(path: 'yt-dlp', label: 'fake');
  }
}

class _FakeResolverUnavailable extends YtDlpExecutableResolver {
  const _FakeResolverUnavailable();

  @override
  Future<YtDlpExecutable?> resolve() async => null;
}

class _FakeRunner extends YtDlpProcessRunner {
  const _FakeRunner({required this.result});

  final ProcessResult result;

  @override
  Future<ProcessResult> run(String executable, List<String> arguments) async {
    return result;
  }

  @override
  Future<Process> start(String executable, List<String> arguments) {
    throw UnimplementedError();
  }
}

void main() {
  group('YtDlpEngineService', () {
    test('parses JSON into formats and recommended id', () async {
      const jsonOutput = '''
{
  "title": "Video Teste",
  "duration": 201,
  "formats": [
    {
      "format_id": "22",
      "ext": "mp4",
      "height": 720,
      "vcodec": "avc1",
      "acodec": "mp4a",
      "filesize": 10485760
    },
    {
      "format_id": "140",
      "ext": "m4a",
      "vcodec": "none",
      "acodec": "mp4a",
      "filesize": 5242880
    }
  ]
}
''';
      final service = YtDlpEngineService(
        resolver: const _FakeResolverAvailable(),
        runner: _FakeRunner(result: ProcessResult(1, 0, jsonOutput, '')),
      );

      final result = await service.analyzeUrl(
        'https://youtube.com/watch?v=abc',
      );

      expect(result.title, 'Video Teste');
      expect(result.durationLabel, '03:21');
      expect(result.formats, isNotEmpty);
      expect(result.formats.any((f) => f.formatLabel == 'MP4'), isTrue);
      expect(result.recommendedFormatId, result.formats.first.id);
    });

    test('throws friendly error when executable is unavailable', () async {
      final service = YtDlpEngineService(
        resolver: const _FakeResolverUnavailable(),
      );

      await expectLater(
        () => service.analyzeUrl('https://youtube.com/watch?v=abc'),
        throwsA(isA<YtDlpEngineException>()),
      );
    });

    test('parses download progress line', () {
      final value = YtDlpEngineService.parseProgressPercent(
        '[download]  42.0% of 10.00MiB at 1.23MiB/s ETA 00:03',
      );
      expect(value, closeTo(0.42, 0.0001));
    });
  });
}
