import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/engine_availability_result.dart';

void main() {
  group('EngineAvailabilityResult', () {
    test('unknown cria status unknown e isAvailable false', () {
      final result = EngineAvailabilityResult.unknown('yt-dlp');
      expect(result.status, EngineAvailabilityStatus.unknown);
      expect(result.isAvailable, isFalse);
    });

    test('available cria status available e isAvailable true', () {
      final result = EngineAvailabilityResult.available(
        executableLabel: 'yt-dlp',
        versionLabel: '2026.01.01',
      );
      expect(result.status, EngineAvailabilityStatus.available);
      expect(result.isAvailable, isTrue);
    });

    test('unavailable cria status unavailable e isAvailable false', () {
      final result = EngineAvailabilityResult.unavailable(
        executableLabel: 'yt-dlp',
        message: 'não encontrado',
      );
      expect(result.status, EngineAvailabilityStatus.unavailable);
      expect(result.isAvailable, isFalse);
    });

    test('versionLabel é preservado', () {
      final result = EngineAvailabilityResult.available(
        executableLabel: 'youtube-dl',
        versionLabel: '2026.05.02',
      );
      expect(result.versionLabel, '2026.05.02');
    });
  });
}
