import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/download/download_output_planner.dart';

void main() {
  group('DownloadOutputPlanner', () {
    const planner = DownloadOutputPlanner();

    test('sanitiza caracteres invalidos e preserva extensao', () async {
      final plan = await planner.plan(requestedFileName: 'a:b*c?d"e<f>g|.mp4');
      expect(plan.fileName.endsWith('.mp4'), isTrue);
      expect(plan.fileName.contains(':'), isFalse);
      expect(plan.fileName.contains('*'), isFalse);
      expect(plan.fileName.contains('?'), isFalse);
      expect(plan.fileName.contains('"'), isFalse);
      expect(plan.fileName.contains('<'), isFalse);
      expect(plan.fileName.contains('>'), isFalse);
      expect(plan.fileName.contains('|'), isFalse);
    });

    test('fallback para nome vazio', () async {
      final plan = await planner.plan(requestedFileName: '   ');
      expect(plan.fileName, 'clipflow-download.bin');
    });

    test('evita sobrescrever quando arquivo existe', () async {
      final plan1 = await planner.plan(requestedFileName: 'arquivo.mp4');
      await plan1.directory.create(recursive: true);
      await plan1.file.writeAsBytes([1, 2, 3]);

      final plan2 = await planner.plan(requestedFileName: 'arquivo.mp4');
      expect(plan2.fileName, 'arquivo (1).mp4');

      if (await plan1.file.exists()) {
        await plan1.file.delete();
      }
    });

    test('cria diretorio de destino', () async {
      final plan = await planner.plan(requestedFileName: 'novo.bin');
      expect(await plan.directory.exists(), isTrue);
    });
  });
}
