import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/internal_engine_service.dart';
import 'package:clipflow_downloader/src/engine/internal_engine_source.dart';

void main() {
  group('InternalEngineService', () {
    const service = InternalEngineService();

    test('classifyUrl rejeita vazio', () {
      final source = service.classifyUrl('   ');
      expect(source.kind, InternalEngineSourceKind.unsupported);
    });

    test('classifyUrl rejeita esquema não http/https', () {
      final source = service.classifyUrl('ftp://example.com/file.mp4');
      expect(source.kind, InternalEngineSourceKind.unsupported);
    });

    test('classifyUrl detecta mp4 como directFile', () {
      final source = service.classifyUrl('https://example.com/video.mp4');
      expect(source.kind, InternalEngineSourceKind.directFile);
    });

    test('classifyUrl detecta mp3/m4a como directFile', () {
      final mp3 = service.classifyUrl('https://example.com/audio.mp3');
      final m4a = service.classifyUrl('https://example.com/audio.m4a');
      expect(mp3.kind, InternalEngineSourceKind.directFile);
      expect(m4a.kind, InternalEngineSourceKind.directFile);
    });

    test('analyzeUrl para mp4 retorna canDownloadDirectly true', () {
      final result = service.analyzeUrl(rawUrl: 'https://example.com/video.mp4');
      expect(result.canDownloadDirectly, isTrue);
    });

    test('analyzeUrl para mp4 retorna formato recomendado', () {
      final result = service.analyzeUrl(rawUrl: 'https://example.com/video.mp4');
      expect(result.formats, isNotEmpty);
      expect(result.recommendedFormatId, result.formats.first.id);
    });

    test('analyzeUrl para webpage retorna canDownloadDirectly false', () {
      final result = service.analyzeUrl(rawUrl: 'https://example.com/watch?v=1');
      expect(result.canDownloadDirectly, isFalse);
      expect(result.formats, isNotEmpty);
    });

    test('analyzeUrl para URL inválida retorna formatos vazios', () {
      final result = service.analyzeUrl(rawUrl: 'nota interna');
      expect(result.formats, isEmpty);
      expect(result.canDownloadDirectly, isFalse);
    });
  });
}
