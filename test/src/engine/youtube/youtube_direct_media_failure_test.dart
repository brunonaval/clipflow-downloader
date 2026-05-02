import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/youtube/youtube_direct_media_failure.dart';
import 'package:clipflow_downloader/src/engine/youtube/youtube_direct_media_locator.dart';

void main() {
  group('YouTubeDirectMediaFailure', () {
    test('preserva reason e message', () {
      const failure = YouTubeDirectMediaFailure(
        reason: YouTubeDirectMediaFailureReason.requiresSignature,
        message: 'Formato exige assinatura; escolha outro formato.',
      );

      expect(failure.reason, YouTubeDirectMediaFailureReason.requiresSignature);
      expect(
        failure.message,
        'Formato exige assinatura; escolha outro formato.',
      );
    });

    test('lookup result com reference', () {
      final reference = YouTubeDirectMediaReference(
        formatId: '18',
        mediaUri: Uri(scheme: 'https', host: 'media.example', path: '/v.mp4'),
        fileExtension: 'mp4',
        safeHostLabel: 'media.example',
      );
      final result = YouTubeDirectMediaLookupResult.reference(reference);

      expect(result.hasReference, isTrue);
      expect(result.reference, isNotNull);
      expect(result.failure, isNull);
    });

    test('lookup result com failure', () {
      const failure = YouTubeDirectMediaFailure(
        reason: YouTubeDirectMediaFailureReason.noDirectUrl,
        message: 'Formato sem URL direta disponível.',
      );
      const result = YouTubeDirectMediaLookupResult.failure(failure);

      expect(result.hasReference, isFalse);
      expect(result.reference, isNull);
      expect(result.failure, isNotNull);
    });
  });
}
