import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/engine_availability_checker.dart';
import 'package:clipflow_downloader/src/engine/engine_availability_result.dart';
import 'package:clipflow_downloader/src/engine/engine_settings.dart';

void main() {
  group('EngineAvailabilityChecker', () {
    const checker = EngineAvailabilityChecker();

    test('custom sem caminho e useSystemExecutable false retorna unavailable', () async {
      const settings = EngineSettings(
        engineType: EngineType.custom,
        useSystemExecutable: false,
        executablePath: '',
      );
      final result = await checker.check(settings);
      expect(result.status, EngineAvailabilityStatus.unavailable);
    });

    test('custom sem caminho e useSystemExecutable true retorna unavailable', () async {
      const settings = EngineSettings(
        engineType: EngineType.custom,
        useSystemExecutable: true,
        executablePath: '',
      );
      final result = await checker.check(settings);
      expect(result.status, EngineAvailabilityStatus.unavailable);
    });

    test('caminho inexistente retorna unavailable sem crash', () async {
      const settings = EngineSettings(
        engineType: EngineType.custom,
        useSystemExecutable: false,
        executablePath: 'C:\\\\__clipflow__\\\\missing-engine.exe',
      );
      final result = await checker.check(settings);
      expect(result.status, EngineAvailabilityStatus.unavailable);
      expect(result.message, isNotEmpty);
    });
  });
}
