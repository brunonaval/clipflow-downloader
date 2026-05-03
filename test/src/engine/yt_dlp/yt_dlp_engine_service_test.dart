import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/downloads/download_format_option.dart';
import 'package:clipflow_downloader/src/engine/download/internal_download_result.dart';
import 'package:clipflow_downloader/src/engine/yt_dlp/ffmpeg_executable.dart';
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

class _FakeFfmpegResolverAvailable extends FfmpegExecutableResolver {
  const _FakeFfmpegResolverAvailable();

  @override
  Future<FfmpegExecutable?> resolve() async {
    return const FfmpegExecutable(
      path: r'C:\tools\ffmpeg\bin\ffmpeg.exe',
      label: 'fake ffmpeg',
    );
  }
}

class _FakeFfmpegResolverUnavailable extends FfmpegExecutableResolver {
  const _FakeFfmpegResolverUnavailable();

  @override
  Future<FfmpegExecutable?> resolve() async => null;
}

class _FakeRunner extends YtDlpProcessRunner {
  _FakeRunner({
    required this.runResult,
    this.startStdoutLines = const ['[download]  42.0%'],
    this.startStderrLines = const [],
    this.startExitCode = 0,
  });

  final ProcessResult runResult;
  final List<String> startStdoutLines;
  final List<String> startStderrLines;
  final int startExitCode;
  List<String>? lastStartArguments;

  @override
  Future<ProcessResult> run(String executable, List<String> arguments) async {
    return runResult;
  }

  @override
  Future<Process> start(String executable, List<String> arguments) async {
    lastStartArguments = List<String>.from(arguments);
    return _FakeProcess(
      startExitCode,
      stdoutLines: startStdoutLines,
      stderrLines: startStderrLines,
    );
  }
}

class _FakeProcess implements Process {
  _FakeProcess(
    this._exitCode, {
    required this.stdoutLines,
    required this.stderrLines,
  });

  final int _exitCode;
  final List<String> stdoutLines;
  final List<String> stderrLines;

  @override
  int get pid => 123;

  @override
  Stream<List<int>> get stderr => Stream<List<int>>.fromIterable(
    stderrLines.map((line) => Uint8List.fromList('$line\n'.codeUnits)),
  );

  @override
  IOSink get stdin => throw UnimplementedError();

  @override
  Stream<List<int>> get stdout => Stream<List<int>>.fromIterable(
    stdoutLines.map((line) => Uint8List.fromList('$line\n'.codeUnits)),
  );

  @override
  Future<int> get exitCode async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    return _exitCode;
  }

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) => true;
}

void main() {
  group('YtDlpEngineService', () {
    test('parses JSON and keeps real format ids', () async {
      const jsonOutput = '''
{
  "title": "Video Teste",
  "duration": 201,
  "formats": [
    {"format_id":"sb2","ext":"mhtml","vcodec":"none","acodec":"none"},
    {"format_id":"18","ext":"mp4","height":360,"vcodec":"avc1","acodec":"mp4a","filesize":10485760},
    {"format_id":"140","ext":"m4a","vcodec":"none","acodec":"mp4a","format_note":"medium","filesize":5242880},
    {"format_id":"299","ext":"mp4","height":1080,"vcodec":"avc1","acodec":"none","filesize":15728640}
  ]
}
''';

      final runner = _FakeRunner(
        runResult: ProcessResult(1, 0, jsonOutput, 'warning: ffmpeg not found'),
      );
      final service = YtDlpEngineService(
        resolver: const _FakeResolverAvailable(),
        ffmpegResolver: const _FakeFfmpegResolverUnavailable(),
        runner: runner,
      );

      final result = await service.analyzeUrl(
        'https://youtube.com/watch?v=abc',
      );

      expect(result.title, 'Video Teste');
      expect(result.durationLabel, '03:21');
      expect(result.formats.any((f) => f.id.startsWith('sb')), isFalse);
      expect(result.formats.any((f) => f.id.startsWith('299-')), isFalse);
      expect(result.recommendedFormatId, isNot('299'));

      final muxed = result.formats.firstWhere((f) => f.id == '18');
      expect(muxed.label, 'Vídeo MP4 360p');
      expect(muxed.detailsLabel.contains('[muxed]'), isTrue);

      final audioOnly = result.formats.firstWhere((f) => f.id == '140');
      expect(audioOnly.label, 'Áudio M4A medium');
      expect(audioOnly.detailsLabel.contains('[audio-only]'), isTrue);

      final videoOnly = result.formats.firstWhere((f) => f.id == '299');
      expect(videoOnly.label, 'Vídeo sem áudio — requer FFmpeg');
      expect(
        videoOnly.detailsLabel.contains('áudio M4A preferido para MP4'),
        isTrue,
      );
      expect(videoOnly.detailsLabel.contains('[video-only]'), isTrue);
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

    test('parses output path from download destination line', () {
      final output = YtDlpEngineService.parseOutputPathFromLogLine(
        r'[download] Destination: C:\Downloads\ClipFlow\video.mp4',
      );
      expect(output, r'C:\Downloads\ClipFlow\video.mp4');
    });

    test('parses output path from merger line', () {
      final output = YtDlpEngineService.parseOutputPathFromLogLine(
        r'[Merger] Merging formats into "C:\Downloads\ClipFlow\final.mp4"',
      );
      expect(output, r'C:\Downloads\ClipFlow\final.mp4');
    });

    test(
      'video-only without FFmpeg fails and does not start process',
      () async {
        final runner = _FakeRunner(runResult: ProcessResult(1, 0, '{}', ''));
        final service = YtDlpEngineService(
          resolver: const _FakeResolverAvailable(),
          ffmpegResolver: const _FakeFfmpegResolverUnavailable(),
          runner: runner,
        );

        final result = await service.download(
          url: 'https://youtube.com/watch?v=abc',
          formatId: '299',
          selectedFormatLabel: 'MP4',
          outputTemplate: '/tmp/out.%(ext)s',
          onProgress: (_) {},
        );

        expect(result.status, InternalDownloadStatus.failed);
        expect(result.message, contains('requer FFmpeg'));
        expect(runner.lastStartArguments, isNull);
      },
    );

    test('video-only MP4 with FFmpeg uses anti-Opus selector', () async {
      final runner = _FakeRunner(runResult: ProcessResult(1, 0, '{}', ''));
      final service = YtDlpEngineService(
        resolver: const _FakeResolverAvailable(),
        ffmpegResolver: const _FakeFfmpegResolverAvailable(),
        runner: runner,
      );

      final result = await service.download(
        url: 'https://youtube.com/watch?v=abc',
        formatId: '137',
        selectedFormatLabel: 'MP4',
        outputTemplate: '/tmp/out.%(ext)s',
        onProgress: (_) {},
      );

      expect(result.status, InternalDownloadStatus.completed);
      final args = runner.lastStartArguments!;
      expect(
        args,
        containsAllInOrder([
          '-f',
          '137+bestaudio[ext=m4a]/137+ba[acodec^=mp4a]/137+140/137+139',
        ]),
      );
      expect(args.where((arg) => arg.contains('bestaudio/best')), isEmpty);
      expect(args, containsAllInOrder(['--merge-output-format', 'mp4']));
      expect(args, contains('--ffmpeg-location'));
    });

    test('muxed id 18 keeps -f 18', () async {
      final runner = _FakeRunner(runResult: ProcessResult(1, 0, '{}', ''));
      final service = YtDlpEngineService(
        resolver: const _FakeResolverAvailable(),
        ffmpegResolver: const _FakeFfmpegResolverUnavailable(),
        runner: runner,
      );

      await service.download(
        url: 'https://youtube.com/watch?v=abc',
        formatId: '18',
        outputTemplate: '/tmp/out.%(ext)s',
        onProgress: (_) {},
      );
      expect(runner.lastStartArguments, containsAllInOrder(['-f', '18']));
    });

    test('audio-only id 140 keeps -f 140', () async {
      final runner = _FakeRunner(runResult: ProcessResult(1, 0, '{}', ''));
      final service = YtDlpEngineService(
        resolver: const _FakeResolverAvailable(),
        ffmpegResolver: const _FakeFfmpegResolverUnavailable(),
        runner: runner,
      );

      await service.download(
        url: 'https://youtube.com/watch?v=abc',
        formatId: '140',
        outputTemplate: '/tmp/out.%(ext)s',
        onProgress: (_) {},
      );
      expect(runner.lastStartArguments, containsAllInOrder(['-f', '140']));
    });

    test('selectedFormatIsVideoOnly true forces merge selector', () async {
      final runner = _FakeRunner(runResult: ProcessResult(1, 0, '{}', ''));
      final service = YtDlpEngineService(
        resolver: const _FakeResolverAvailable(),
        ffmpegResolver: const _FakeFfmpegResolverAvailable(),
        runner: runner,
      );

      await service.download(
        url: 'https://youtube.com/watch?v=abc',
        formatId: '999',
        selectedFormatLabel: 'MP4',
        selectedFormatIsVideoOnly: true,
        outputTemplate: '/tmp/out.%(ext)s',
        onProgress: (_) {},
      );

      expect(
        runner.lastStartArguments,
        containsAllInOrder([
          '-f',
          '999+bestaudio[ext=m4a]/999+ba[acodec^=mp4a]/999+140/999+139',
        ]),
      );
    });

    test('friendly message for format unavailable', () async {
      final runner = _FakeRunner(
        runResult: ProcessResult(1, 0, '{}', ''),
        startExitCode: 1,
        startStderrLines: const ['ERROR: Requested format is not available'],
      );
      final service = YtDlpEngineService(
        resolver: const _FakeResolverAvailable(),
        ffmpegResolver: const _FakeFfmpegResolverAvailable(),
        runner: runner,
      );

      final result = await service.download(
        url: 'https://youtube.com/watch?v=abc',
        formatId: '137',
        selectedFormatLabel: 'MP4',
        outputTemplate: '/tmp/out.%(ext)s',
        onProgress: (_) {},
      );

      expect(result.status, InternalDownloadStatus.failed);
      expect(
        result.message,
        'Não foi possível encontrar áudio M4A/AAC compatível para gerar MP4.',
      );
    });

    test('merge final path has priority over temporary destination', () async {
      final runner = _FakeRunner(
        runResult: ProcessResult(1, 0, '{}', ''),
        startStdoutLines: const [
          r'[download] Destination: C:\Downloads\ClipFlow\temp.f299.mp4',
          '[Merger] Merging formats into "C:\\Downloads\\ClipFlow\\final.mp4"',
          '[download]  42.0%',
        ],
      );
      final service = YtDlpEngineService(
        resolver: const _FakeResolverAvailable(),
        ffmpegResolver: const _FakeFfmpegResolverAvailable(),
        runner: runner,
      );

      final result = await service.download(
        url: 'https://youtube.com/watch?v=abc',
        formatId: '299',
        selectedFormatLabel: 'MP4',
        outputTemplate: '/tmp/out.%(ext)s',
        onProgress: (_) {},
      );

      expect(result.status, InternalDownloadStatus.completed);
      expect(result.outputPath, r'C:\Downloads\ClipFlow\final.mp4');
    });

    test('detects video-only option helper by detailsLabel', () {
      const videoOnly = DownloadFormatOption(
        id: '299',
        kind: DownloadFormatKind.video,
        label: 'Vídeo sem áudio — requer FFmpeg',
        formatLabel: 'MP4',
        qualityLabel: '1080p',
        sizeLabel: '15 MB',
        detailsLabel:
            '[video-only] yt-dlp format 299 · vídeo sem áudio · requer FFmpeg · áudio M4A preferido para MP4',
      );

      expect(YtDlpEngineService.isVideoOnlyOption(videoOnly), isTrue);
    });
  });
}
