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

    test('classifyUrl rejeita esquema nao http/https', () {
      final source = service.classifyUrl('ftp://example.com/file.mp4');
      expect(source.kind, InternalEngineSourceKind.unsupported);
    });

    test('classifyUrl detecta URL do YouTube como webpage com label YouTube', () {
      final source = service.classifyUrl('https://www.youtube.com/watch?v=abc123');
      expect(source.kind, InternalEngineSourceKind.webpage);
      expect(source.label, contains('YouTube'));
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

    test('analyzeUrl para YouTube retorna title contendo YouTube', () {
      final result = service.analyzeUrl(
        rawUrl: 'https://www.youtube.com/watch?v=abc123',
      );
      expect(result.title, contains('YouTube'));
    });

    test('analyzeUrl para YouTube retorna formatos', () {
      final result = service.analyzeUrl(rawUrl: 'https://youtu.be/abc123');
      expect(result.formats, isNotEmpty);
      expect(result.recommendedFormatId, isNotNull);
    });

    test('analyzeUrl para YouTube retorna canDownloadDirectly false', () {
      final result = service.analyzeUrl(rawUrl: 'https://youtu.be/abc123');
      expect(result.canDownloadDirectly, isFalse);
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

    test('analyzeUrl para URL invalida retorna formatos vazios', () {
      final result = service.analyzeUrl(rawUrl: 'nota interna');
      expect(result.formats, isEmpty);
      expect(result.canDownloadDirectly, isFalse);
    });
  });
}
