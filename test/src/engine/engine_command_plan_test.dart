import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/engine_command_plan.dart';

void main() {
  group('EngineCommandPlan', () {
    test('preview contem engineLabel', () {
      const plan = EngineCommandPlan(
        type: EngineCommandPlanType.download,
        engineLabel: 'Motor interno',
        arguments: ['--format', 'video-mp4-1080p'],
        summaryLabel: 'Plano',
      );

      expect(plan.preview, contains('Motor interno'));
    });

    test('preview contem argumentos', () {
      const plan = EngineCommandPlan(
        type: EngineCommandPlanType.download,
        engineLabel: 'Motor interno',
        arguments: ['--format', 'video-mp4-1080p'],
        summaryLabel: 'Plano',
      );

      expect(plan.preview, contains('--format'));
      expect(plan.preview, contains('video-mp4-1080p'));
    });

    test('isExecutable default e false', () {
      const plan = EngineCommandPlan(
        type: EngineCommandPlanType.download,
        engineLabel: 'Motor interno',
        arguments: [],
        summaryLabel: 'Plano',
      );

      expect(plan.isExecutable, isFalse);
    });

    test('type e preservado', () {
      const plan = EngineCommandPlan(
        type: EngineCommandPlanType.analyze,
        engineLabel: 'Motor interno',
        arguments: [],
        summaryLabel: 'Plano',
      );

      expect(plan.type, EngineCommandPlanType.analyze);
    });
  });
}
