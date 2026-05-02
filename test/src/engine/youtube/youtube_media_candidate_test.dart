import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/youtube/youtube_media_candidate.dart';

void main() {
  group('YouTubeMediaCandidate', () {
    test('direct preserva host e canAttemptDirectDownload true', () {
      const candidate = YouTubeMediaCandidate(
        formatId: '18',
        kind: YouTubeMediaCandidateKind.direct,
        safeHostLabel: 'rr1---sn.example.googlevideo.com',
        canAttemptDirectDownload: true,
        reasonLabel: 'URL direta detectada pelo player',
      );

      expect(candidate.safeHostLabel, 'rr1---sn.example.googlevideo.com');
      expect(candidate.canAttemptDirectDownload, isTrue);
    });

    test('requiresSignature não permite download', () {
      const candidate = YouTubeMediaCandidate(
        formatId: '137',
        kind: YouTubeMediaCandidateKind.requiresSignature,
        canAttemptDirectDownload: false,
        reasonLabel: 'Formato exige assinatura; não suportado nesta versão',
      );

      expect(candidate.canAttemptDirectDownload, isFalse);
      expect(candidate.kind, YouTubeMediaCandidateKind.requiresSignature);
    });

    test('unavailable não permite download', () {
      const candidate = YouTubeMediaCandidate(
        formatId: '999',
        kind: YouTubeMediaCandidateKind.unavailable,
        canAttemptDirectDownload: false,
        reasonLabel: 'Formato sem URL direta disponível',
      );

      expect(candidate.canAttemptDirectDownload, isFalse);
      expect(candidate.kind, YouTubeMediaCandidateKind.unavailable);
    });

    test('modelo não tem campo url', () {
      const candidate = YouTubeMediaCandidate(
        formatId: '18',
        kind: YouTubeMediaCandidateKind.direct,
        safeHostLabel: 'example.com',
        canAttemptDirectDownload: true,
        reasonLabel: 'URL direta detectada pelo player',
      );

      final map = <String, Object?>{
        'formatId': candidate.formatId,
        'kind': candidate.kind.name,
        'safeHostLabel': candidate.safeHostLabel,
        'canAttemptDirectDownload': candidate.canAttemptDirectDownload,
        'reasonLabel': candidate.reasonLabel,
      };

      expect(map.containsKey('url'), isFalse);
    });
  });
}
