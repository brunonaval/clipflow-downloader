import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/mock_engine_service.dart';

void main() {
  group('MockEngineService', () {
    const service = MockEngineService();

    test('analyzeMockUrl retorna título mockado', () {
      final result = service.analyzeMockUrl(sourceUrl: 'https://example.com');
      expect(result.title, 'Link autorizado analisado');
    });

    test('analyzeMockUrl retorna 4 formatos', () {
      final result = service.analyzeMockUrl();
      expect(result.formats, hasLength(4));
    });

    test('recommendedFormatId é video-mp4-1080p', () {
      final result = service.analyzeMockUrl();
      expect(result.recommendedFormatId, 'video-mp4-1080p');
    });

    test('formato recomendado existe e isRecommended é true', () {
      final result = service.analyzeMockUrl();
      final recommended = result.formats.firstWhere(
        (f) => f.id == result.recommendedFormatId,
      );
      expect(recommended.isRecommended, isTrue);
    });

    test('sourceLabel inclui a pasta informada', () {
      final result = service.analyzeMockUrl(outputFolderLabel: 'Downloads');
      expect(result.sourceLabel, contains('Downloads'));
    });

    test('lista de formatos é imutável para uso básico', () {
      final result = service.analyzeMockUrl();
      expect(
        () => result.formats.add(result.formats.first),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
