import 'dart:io';

class SystemFileOpener {
  const SystemFileOpener({
    SystemCommandRunner runner = const _DefaultSystemCommandRunner(),
    SystemPlatformResolver platformResolver =
        const _DefaultSystemPlatformResolver(),
  }) : _runner = runner,
       _platformResolver = platformResolver;

  final SystemCommandRunner _runner;
  final SystemPlatformResolver _platformResolver;

  Future<void> openFile(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Path vazio para abrir arquivo.');
    }
    final command = _commandForCurrentPlatform();
    await _runner.start(command, [trimmed]);
  }

  Future<void> openFolder(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Path vazio para abrir pasta.');
    }
    final command = _commandForCurrentPlatform();
    await _runner.start(command, [trimmed]);
  }

  String _commandForCurrentPlatform() {
    switch (_platformResolver.current()) {
      case SystemPlatform.windows:
        return 'explorer';
      case SystemPlatform.macos:
        return 'open';
      case SystemPlatform.linux:
        return 'xdg-open';
    }
  }
}

enum SystemPlatform { windows, macos, linux }

abstract class SystemPlatformResolver {
  const SystemPlatformResolver();

  SystemPlatform current();
}

class _DefaultSystemPlatformResolver extends SystemPlatformResolver {
  const _DefaultSystemPlatformResolver();

  @override
  SystemPlatform current() {
    if (Platform.isWindows) return SystemPlatform.windows;
    if (Platform.isMacOS) return SystemPlatform.macos;
    return SystemPlatform.linux;
  }
}

abstract class SystemCommandRunner {
  const SystemCommandRunner();

  Future<Process> start(String executable, List<String> arguments);
}

class _DefaultSystemCommandRunner extends SystemCommandRunner {
  const _DefaultSystemCommandRunner();

  @override
  Future<Process> start(String executable, List<String> arguments) {
    return Process.start(executable, arguments);
  }
}
