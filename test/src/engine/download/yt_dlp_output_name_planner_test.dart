import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/download/yt_dlp_output_name_planner.dart';

void main() {
  group('YtDlpOutputNamePlanner', () {
    const planner = YtDlpOutputNamePlanner();

    test('returns requested name when directory has no collision', () async {
      final dir = await Directory.systemTemp.createTemp('clipflow-output-');
      final base = await planner.uniqueBaseName(
        directory: dir,
        requestedBaseName: 'Titulo',
      );
      expect(base, 'Titulo');
      await dir.delete(recursive: true);
    });

    test('returns numbered name when final file already exists', () async {
      final dir = await Directory.systemTemp.createTemp('clipflow-output-');
      await File(
        '${dir.path}${Platform.pathSeparator}Titulo.mp4',
      ).writeAsString('ok');

      final base = await planner.uniqueBaseName(
        directory: dir,
        requestedBaseName: 'Titulo',
      );
      expect(base, 'Titulo (1)');
      await dir.delete(recursive: true);
    });

    test('considers yt-dlp temp fragments as collision', () async {
      final dir = await Directory.systemTemp.createTemp('clipflow-output-');
      await File(
        '${dir.path}${Platform.pathSeparator}Titulo.f137.mp4',
      ).writeAsString('ok');

      final base = await planner.uniqueBaseName(
        directory: dir,
        requestedBaseName: 'Titulo',
      );
      expect(base, 'Titulo (1)');
      await dir.delete(recursive: true);
    });
  });
}
