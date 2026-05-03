import 'dart:io';

import '../../settings/output_folder_choice.dart';

class OutputDirectoryResolver {
  const OutputDirectoryResolver({
    Map<String, String>? environment,
    bool? isWindows,
    String? tempPath,
  }) : _environment = environment,
       _isWindows = isWindows,
       _tempPath = tempPath;

  final Map<String, String>? _environment;
  final bool? _isWindows;
  final String? _tempPath;

  Future<Directory> resolve(OutputFolderChoice choice) async {
    final base = _baseDirectoryFor(choice);
    final safeBase = base?.trim();

    if (safeBase != null && safeBase.isNotEmpty) {
      final path = choice.type == OutputFolderType.custom
          ? safeBase
          : '$safeBase${Platform.pathSeparator}ClipFlow';
      final directory = Directory(path);
      await directory.create(recursive: true);
      return directory;
    }

    final fallback = Directory(
      '${_tempPath ?? Directory.systemTemp.path}${Platform.pathSeparator}ClipFlow',
    );
    await fallback.create(recursive: true);
    return fallback;
  }

  String? _baseDirectoryFor(OutputFolderChoice choice) {
    if (choice.type == OutputFolderType.custom) {
      return choice.customPath;
    }

    final env = _environment ?? Platform.environment;
    final isWindows = _isWindows ?? Platform.isWindows;
    final home = isWindows ? env['USERPROFILE'] : env['HOME'];
    if (home == null || home.trim().isEmpty) {
      return null;
    }

    final folderName = switch (choice.type) {
      OutputFolderType.downloads => 'Downloads',
      OutputFolderType.videos => 'Videos',
      OutputFolderType.documents => 'Documents',
      OutputFolderType.custom => '',
    };

    return '$home${Platform.pathSeparator}$folderName';
  }
}
