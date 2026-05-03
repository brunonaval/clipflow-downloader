import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/download/completed_output_resolver.dart';

void main() {
  group('CompletedOutputResolver', () {
    const resolver = CompletedOutputResolver();

    test('reportedOutputPath existente vence', () async {
      final dir = await Directory.systemTemp.createTemp('clipflow-resolver-');
      final file = File('${dir.path}${Platform.pathSeparator}video.mp4');
      await file.writeAsString('ok');

      final resolved = await resolver.resolve(
        reportedOutputPath: file.path,
        outputDirectoryPath: dir.path,
        baseName: 'video',
      );

      expect(resolved, file.path);
      await dir.delete(recursive: true);
    });

    test('reportedOutputPath inexistente não é usado', () async {
      final dir = await Directory.systemTemp.createTemp('clipflow-resolver-');
      final candidate = File('${dir.path}${Platform.pathSeparator}video-a.mp4');
      await candidate.writeAsString('ok');

      final resolved = await resolver.resolve(
        reportedOutputPath:
            '${dir.path}${Platform.pathSeparator}missing-output.mp4',
        outputDirectoryPath: dir.path,
        baseName: 'video-a',
      );

      expect(resolved, candidate.path);
      await dir.delete(recursive: true);
    });

    test('template com %(ext)s é ignorado', () async {
      final dir = await Directory.systemTemp.createTemp('clipflow-resolver-');
      final candidate = File('${dir.path}${Platform.pathSeparator}video.mp4');
      await candidate.writeAsString('ok');

      final resolved = await resolver.resolve(
        reportedOutputPath: '${dir.path}${Platform.pathSeparator}video.%(ext)s',
        outputDirectoryPath: dir.path,
        baseName: 'video',
      );

      expect(resolved, candidate.path);
      await dir.delete(recursive: true);
    });

    test('localiza arquivo mais recente por baseName no diretório', () async {
      final dir = await Directory.systemTemp.createTemp('clipflow-resolver-');
      final older = File('${dir.path}${Platform.pathSeparator}abc-old.mp4');
      final newer = File('${dir.path}${Platform.pathSeparator}abc-new.mp4');
      await older.writeAsString('1');
      await Future<void>.delayed(const Duration(milliseconds: 15));
      await newer.writeAsString('2');

      final resolved = await resolver.resolve(
        reportedOutputPath: null,
        outputDirectoryPath: dir.path,
        baseName: 'abc',
      );

      expect(resolved, newer.path);
      await dir.delete(recursive: true);
    });

    test('retorna null quando não encontra arquivo', () async {
      final dir = await Directory.systemTemp.createTemp('clipflow-resolver-');
      final resolved = await resolver.resolve(
        reportedOutputPath: null,
        outputDirectoryPath: dir.path,
        baseName: 'nao-existe',
      );
      expect(resolved, isNull);
      await dir.delete(recursive: true);
    });
  });
}
