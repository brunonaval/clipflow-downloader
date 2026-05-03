import 'dart:async';
import 'dart:io';

import 'internal_download_cancellation.dart';
import 'internal_download_progress.dart';
import 'internal_download_request.dart';
import 'internal_download_result.dart';

class InternalHttpDownloader {
  const InternalHttpDownloader();

  Future<InternalDownloadResult> download({
    required InternalDownloadRequest request,
    required IOSink sink,
    required void Function(InternalDownloadProgress progress) onProgress,
    InternalDownloadCancellation? cancellation,
  }) async {
    if (!request.isHttpOrHttps) {
      return const InternalDownloadResult(
        status: InternalDownloadStatus.failed,
        message: 'URL de download inválida: use apenas http/https.',
        receivedBytes: 0,
      );
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    var receivedBytes = 0;

    try {
      final uri = request.sourceUri;
      final httpRequest = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 15));
      final response = await httpRequest.close().timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode != HttpStatus.ok) {
        return InternalDownloadResult(
          status: InternalDownloadStatus.failed,
          message: 'Falha HTTP ${response.statusCode} ao baixar arquivo.',
          receivedBytes: 0,
        );
      }

      final totalBytes = response.contentLength >= 0
          ? response.contentLength
          : null;

      await for (final chunk in response) {
        if (cancellation?.isCanceled ?? false) {
          return InternalDownloadResult(
            status: InternalDownloadStatus.canceled,
            message: 'Download cancelado.',
            receivedBytes: receivedBytes,
          );
        }

        sink.add(chunk);
        receivedBytes += chunk.length;

        onProgress(
          InternalDownloadProgress(
            receivedBytes: receivedBytes,
            totalBytes: totalBytes,
            isDone: false,
          ),
        );
      }

      await sink.flush();

      onProgress(
        InternalDownloadProgress(
          receivedBytes: receivedBytes,
          totalBytes: totalBytes,
          isDone: true,
        ),
      );

      return InternalDownloadResult(
        status: InternalDownloadStatus.completed,
        message: 'Download concluído.',
        receivedBytes: receivedBytes,
      );
    } on TimeoutException {
      return InternalDownloadResult(
        status: InternalDownloadStatus.failed,
        message: 'Tempo limite ao iniciar download.',
        receivedBytes: receivedBytes,
      );
    } catch (_) {
      return InternalDownloadResult(
        status: InternalDownloadStatus.failed,
        message: 'Falha ao baixar arquivo nesta sessão.',
        receivedBytes: receivedBytes,
      );
    } finally {
      client.close(force: true);
    }
  }
}
