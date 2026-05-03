import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/download/output_directory_resolver.dart';
import 'package:clipflow_downloader/src/settings/output_folder_choice.dart';

void main() {
  test('downloads usa USERPROFILE quando disponível', () async {
    final fakeHome =
        '${Directory.systemTemp.path}${Platform.pathSeparator}clipflow_home_win';
    final resolver = OutputDirectoryResolver(
      environment: {'USERPROFILE': fakeHome},
      isWindows: true,
      tempPath:
          '${Directory.systemTemp.path}${Platform.pathSeparator}clipflow_tmp',
    );

    final directory = await resolver.resolve(OutputFolderChoice.downloads);

    expect(directory.path, contains(fakeHome));
    expect(directory.path, contains('Downloads'));
    expect(directory.path, endsWith('ClipFlow'));
  });

  test('videos e documents montam caminho esperado', () async {
    final fakeHome =
        '${Directory.systemTemp.path}${Platform.pathSeparator}clipflow_home_unix';
    final resolver = OutputDirectoryResolver(
      environment: {'HOME': fakeHome},
      isWindows: false,
      tempPath:
          '${Directory.systemTemp.path}${Platform.pathSeparator}clipflow_tmp',
    );

    final videos = await resolver.resolve(
      const OutputFolderChoice(type: OutputFolderType.videos, label: 'Vídeos'),
    );
    final documents = await resolver.resolve(
      const OutputFolderChoice(
        type: OutputFolderType.documents,
        label: 'Documentos',
      ),
    );

    expect(
      videos.path,
      '$fakeHome${Platform.pathSeparator}Videos${Platform.pathSeparator}ClipFlow',
    );
    expect(
      documents.path,
      '$fakeHome${Platform.pathSeparator}Documents${Platform.pathSeparator}ClipFlow',
    );
  });

  test('custom usa customPath direto', () async {
    final customPath =
        '${Directory.systemTemp.path}${Platform.pathSeparator}clipflow_custom';
    final resolver = OutputDirectoryResolver(
      environment: {},
      isWindows: false,
      tempPath:
          '${Directory.systemTemp.path}${Platform.pathSeparator}clipflow_tmp',
    );

    final custom = await resolver.resolve(
      OutputFolderChoice(
        type: OutputFolderType.custom,
        label: 'Personalizada',
        customPath: customPath,
      ),
    );

    expect(custom.path, customPath);
  });

  test('fallback para temp quando env ausente', () async {
    final fallbackTemp =
        '${Directory.systemTemp.path}${Platform.pathSeparator}clipflow_temp_fallback';
    final resolver = OutputDirectoryResolver(
      environment: {},
      isWindows: true,
      tempPath: fallbackTemp,
    );

    final directory = await resolver.resolve(OutputFolderChoice.downloads);

    expect(directory.path, contains(fallbackTemp));
    expect(directory.path, endsWith('ClipFlow'));
  });
}
