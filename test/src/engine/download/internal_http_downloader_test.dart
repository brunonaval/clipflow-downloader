import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/download/internal_download_cancellation.dart';
import 'package:clipflow_downloader/src/engine/download/internal_download_progress.dart';
import 'package:clipflow_downloader/src/engine/download/internal_download_request.dart';
import 'package:clipflow_downloader/src/engine/download/internal_download_result.dart';
import 'package:clipflow_downloader/src/engine/download/internal_http_downloader.dart';

void main() {
  group('InternalHttpDownloader', () {
    const downloader = InternalHttpDownloader();

    test('download completo escreve bytes no sink e chama progress', () async {
      final payload = List<int>.generate(4096, (i) => i % 256);
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));

      server.listen((request) async {
        request.response.statusCode = HttpStatus.ok;
        request.response.contentLength = payload.length;
        request.response.add(payload);
        await request.response.close();
      });

      final tempDir = await Directory.systemTemp.createTemp(
        'clipflow-download-test',
      );
      addTearDown(() => tempDir.delete(recursive: true));
      final outputFile = File('${tempDir.path}/output.bin');
      final sink = outputFile.openWrite();

      final progressEvents = <InternalDownloadProgress>[];
      final result = await downloader.download(
        request: InternalDownloadRequest(
          sourceUri: Uri.parse(
            'http://${server.address.host}:${server.port}/file.bin',
          ),
          fileName: 'file.bin',
        ),
        sink: sink,
        onProgress: progressEvents.add,
      );

      await sink.close();

      final written = await outputFile.readAsBytes();
      expect(result.status, InternalDownloadStatus.completed);
      expect(result.receivedBytes, payload.length);
      expect(written, payload);
      expect(progressEvents, isNotEmpty);
      expect(progressEvents.last.isDone, isTrue);
    });

    test('cancelamento retorna canceled', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));

      server.listen((request) async {
        request.response.statusCode = HttpStatus.ok;
        request.response.contentLength = 1024 * 1024;
        for (var i = 0; i < 128; i++) {
          request.response.add(List<int>.filled(8192, i % 255));
          await Future<void>.delayed(const Duration(milliseconds: 2));
        }
        await request.response.close();
      });

      final tempDir = await Directory.systemTemp.createTemp(
        'clipflow-download-cancel-test',
      );
      addTearDown(() => tempDir.delete(recursive: true));
      final outputFile = File('${tempDir.path}/output.bin');
      final sink = outputFile.openWrite();

      final cancellation = InternalDownloadCancellation();
      var firstProgress = true;
      final result = await downloader.download(
        request: InternalDownloadRequest(
          sourceUri: Uri.parse(
            'http://${server.address.host}:${server.port}/slow.bin',
          ),
          fileName: 'slow.bin',
        ),
        sink: sink,
        cancellation: cancellation,
        onProgress: (progress) {
          if (firstProgress && progress.receivedBytes > 0) {
            firstProgress = false;
            cancellation.cancel();
          }
        },
      );

      await sink.close();

      expect(result.status, InternalDownloadStatus.canceled);
      expect(result.receivedBytes, greaterThan(0));
    });

    test('URL nao http/https retorna failed', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'clipflow-download-invalid-url',
      );
      addTearDown(() => tempDir.delete(recursive: true));
      final outputFile = File('${tempDir.path}/output.bin');
      final sink = outputFile.openWrite();

      final result = await downloader.download(
        request: InternalDownloadRequest(
          sourceUri: Uri.parse('ftp://example.com/file.bin'),
          fileName: 'file.bin',
        ),
        sink: sink,
        onProgress: (_) {},
      );

      await sink.close();

      expect(result.status, InternalDownloadStatus.failed);
      expect(result.message, contains('http/https'));
    });

    test('HTTP 404 retorna failed', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));

      server.listen((request) async {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      });

      final tempDir = await Directory.systemTemp.createTemp(
        'clipflow-download-404-test',
      );
      addTearDown(() => tempDir.delete(recursive: true));
      final outputFile = File('${tempDir.path}/output.bin');
      final sink = outputFile.openWrite();

      final result = await downloader.download(
        request: InternalDownloadRequest(
          sourceUri: Uri.parse(
            'http://${server.address.host}:${server.port}/missing.bin',
          ),
          fileName: 'missing.bin',
        ),
        sink: sink,
        onProgress: (_) {},
      );

      await sink.close();

      expect(result.status, InternalDownloadStatus.failed);
      expect(result.message, contains('HTTP 404'));
    });
  });
}
