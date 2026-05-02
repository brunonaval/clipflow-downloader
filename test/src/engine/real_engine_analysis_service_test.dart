import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/engine_settings.dart';
import 'package:clipflow_downloader/src/engine/real_engine_analysis_service.dart';

void main() {
  group('RealEngineAnalysisService', () {
    const service = RealEngineAnalysisService();

    test('URL vazia falha com EngineAnalysisException', () async {
      await expectLater(
        () => service.analyzeUrl(
          settings: const EngineSettings(),
          sourceUrl: '   ',
        ),
        throwsA(isA<EngineAnalysisException>()),
      );
    });

    test('URL não http/https falha', () async {
      await expectLater(
        () => service.analyzeUrl(
          settings: const EngineSettings(),
          sourceUrl: 'ftp://example.com/file',
        ),
        throwsA(isA<EngineAnalysisException>()),
      );
    });

    test('custom engine sem path falha', () async {
      await expectLater(
        () => service.analyzeUrl(
          settings: const EngineSettings(
            engineType: EngineType.custom,
            useSystemExecutable: false,
            executablePath: '',
          ),
          sourceUrl: 'https://example.com/video',
        ),
        throwsA(isA<EngineAnalysisException>()),
      );
    });

    test('caminho inexistente retorna falha controlada sem crash', () async {
      await expectLater(
        () => service.analyzeUrl(
          settings: const EngineSettings(
            engineType: EngineType.custom,
            useSystemExecutable: false,
            executablePath: 'C:\\\\__clipflow__\\\\missing-engine.exe',
          ),
          sourceUrl: 'https://example.com/video',
        ),
        throwsA(isA<EngineAnalysisException>()),
      );
    });
  });
}
