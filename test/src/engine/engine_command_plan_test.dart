import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/engine_command_plan.dart';

void main() {
  group('EngineCommandPlan', () {
    test('preview contém executableLabel', () {
      const plan = EngineCommandPlan(
        type: EngineCommandPlanType.download,
        executableLabel: 'yt-dlp',
        arguments: ['--format', 'video-mp4-1080p'],
        summaryLabel: 'Plano',
      );

      expect(plan.preview, contains('yt-dlp'));
    });

    test('preview contém argumentos', () {
      const plan = EngineCommandPlan(
        type: EngineCommandPlanType.download,
        executableLabel: 'yt-dlp',
        arguments: ['--format', 'video-mp4-1080p'],
        summaryLabel: 'Plano',
      );

      expect(plan.preview, contains('--format'));
      expect(plan.preview, contains('video-mp4-1080p'));
    });

    test('isExecutable default é false', () {
      const plan = EngineCommandPlan(
        type: EngineCommandPlanType.download,
        executableLabel: 'yt-dlp',
        arguments: [],
        summaryLabel: 'Plano',
      );

      expect(plan.isExecutable, isFalse);
    });

    test('type é preservado', () {
      const plan = EngineCommandPlan(
        type: EngineCommandPlanType.analyze,
        executableLabel: 'yt-dlp',
        arguments: [],
        summaryLabel: 'Plano',
      );

      expect(plan.type, EngineCommandPlanType.analyze);
    });
  });
}
