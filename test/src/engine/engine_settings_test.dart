import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/engine_settings.dart';

void main() {
  group('EngineSettings', () {
    test('has expected defaults', () {
      const settings = EngineSettings();

      expect(settings.engineType, EngineType.ytDlp);
      expect(settings.useSystemExecutable, isTrue);
      expect(settings.executablePath, isEmpty);
      expect(settings.acceptedLegalUsage, isFalse);
      expect(settings.status, EngineSetupStatus.notConfigured);
    });

    test('engineLabel returns expected labels', () {
      expect(
        const EngineSettings(engineType: EngineType.ytDlp).engineLabel,
        'yt-dlp',
      );
      expect(
        const EngineSettings(engineType: EngineType.youtubeDl).engineLabel,
        'youtube-dl',
      );
      expect(
        const EngineSettings(engineType: EngineType.custom).engineLabel,
        'Personalizado',
      );
    });

    test('statusLabel returns expected labels', () {
      expect(
        const EngineSettings(status: EngineSetupStatus.notConfigured).statusLabel,
        'Motor não configurado',
      );
      expect(
        const EngineSettings(status: EngineSetupStatus.configuredMock).statusLabel,
        'Configuração mockada salva',
      );
    });

    test('canSaveMockConfiguration is false when legal usage not accepted', () {
      const settings = EngineSettings(
        acceptedLegalUsage: false,
        useSystemExecutable: true,
      );

      expect(settings.canSaveMockConfiguration, isFalse);
    });

    test('canSaveMockConfiguration is true for system executable with legal usage', () {
      const settings = EngineSettings(
        acceptedLegalUsage: true,
        useSystemExecutable: true,
        executablePath: '',
      );

      expect(settings.canSaveMockConfiguration, isTrue);
    });

    test('canSaveMockConfiguration is false for custom executable with empty path', () {
      const settings = EngineSettings(
        acceptedLegalUsage: true,
        useSystemExecutable: false,
        executablePath: '   ',
      );

      expect(settings.canSaveMockConfiguration, isFalse);
    });

    test('canSaveMockConfiguration is true for custom executable with path', () {
      const settings = EngineSettings(
        acceptedLegalUsage: true,
        useSystemExecutable: false,
        executablePath: r'C:\tools\yt-dlp.exe',
      );

      expect(settings.canSaveMockConfiguration, isTrue);
    });

    test('copyWith updates only provided fields', () {
      const base = EngineSettings();

      final updated = base.copyWith(
        engineType: EngineType.custom,
        useSystemExecutable: false,
      );

      expect(updated.engineType, EngineType.custom);
      expect(updated.useSystemExecutable, isFalse);
      expect(updated.executablePath, base.executablePath);
      expect(updated.acceptedLegalUsage, base.acceptedLegalUsage);
      expect(updated.status, base.status);
    });
  });
}
