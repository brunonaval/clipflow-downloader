import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/system/system_file_opener.dart';

class _FakeRunner extends SystemCommandRunner {
  String? executable;
  List<String>? arguments;

  @override
  Future<Process> start(String executable, List<String> arguments) async {
    this.executable = executable;
    this.arguments = List<String>.from(arguments);
    throw UnimplementedError('not needed for tests');
  }
}

class _FakePlatformResolver extends SystemPlatformResolver {
  _FakePlatformResolver(this.platform);

  final SystemPlatform platform;

  @override
  SystemPlatform current() => platform;
}

void main() {
  group('SystemFileOpener', () {
    test('Windows open folder monta explorer args', () async {
      final runner = _FakeRunner();
      final opener = SystemFileOpener(
        runner: runner,
        platformResolver: _FakePlatformResolver(SystemPlatform.windows),
      );

      try {
        await opener.openFolder(r'C:\Downloads\ClipFlow');
      } catch (_) {}

      expect(runner.executable, 'explorer');
      expect(runner.arguments, [r'C:\Downloads\ClipFlow']);
    });

    test('Windows open file monta explorer args', () async {
      final runner = _FakeRunner();
      final opener = SystemFileOpener(
        runner: runner,
        platformResolver: _FakePlatformResolver(SystemPlatform.windows),
      );

      try {
        await opener.openFile(r'C:\Downloads\ClipFlow\video.mp4');
      } catch (_) {}

      expect(runner.executable, 'explorer');
      expect(runner.arguments, [r'C:\Downloads\ClipFlow\video.mp4']);
    });

    test('Linux usa xdg-open', () async {
      final runner = _FakeRunner();
      final opener = SystemFileOpener(
        runner: runner,
        platformResolver: _FakePlatformResolver(SystemPlatform.linux),
      );

      try {
        await opener.openFolder('/home/user/Downloads/ClipFlow');
      } catch (_) {}

      expect(runner.executable, 'xdg-open');
      expect(runner.arguments, ['/home/user/Downloads/ClipFlow']);
    });

    test('macOS usa open', () async {
      final runner = _FakeRunner();
      final opener = SystemFileOpener(
        runner: runner,
        platformResolver: _FakePlatformResolver(SystemPlatform.macos),
      );

      try {
        await opener.openFile('/Users/user/Downloads/ClipFlow/video.mp4');
      } catch (_) {}

      expect(runner.executable, 'open');
      expect(runner.arguments, ['/Users/user/Downloads/ClipFlow/video.mp4']);
    });
  });
}
