import 'dart:async';
import 'dart:io';

import 'engine_availability_result.dart';
import 'engine_settings.dart';

class EngineAvailabilityChecker {
  const EngineAvailabilityChecker();

  Future<EngineAvailabilityResult> check(EngineSettings settings) async {
    final executable = _resolveExecutable(settings);
    if (executable == null) {
      return EngineAvailabilityResult.unavailable(
        executableLabel: settings.engineLabel,
        message: 'Informe um executável válido para verificar o motor',
      );
    }

    try {
      final result = await Process.run(
        executable,
        const ['--version'],
      ).timeout(const Duration(seconds: 3));

      if (result.exitCode == 0) {
        final stdoutText = result.stdout.toString().trim();
        final version = stdoutText.isEmpty ? 'versão detectada' : stdoutText;
        return EngineAvailabilityResult.available(
          executableLabel: executable,
          versionLabel: version,
        );
      }

      final stderrText = result.stderr.toString().trim();
      final stdoutText = result.stdout.toString().trim();
      final details = stderrText.isNotEmpty ? stderrText : stdoutText;

      return EngineAvailabilityResult.unavailable(
        executableLabel: executable,
        message: details.isEmpty ? 'Falha ao verificar versão do motor' : details,
      );
    } on TimeoutException {
      return EngineAvailabilityResult.unavailable(
        executableLabel: executable,
        message: 'Tempo limite ao verificar motor',
      );
    } catch (e) {
      return EngineAvailabilityResult.unavailable(
        executableLabel: executable,
        message: 'Não foi possível verificar o motor: $e',
      );
    }
  }

  String? _resolveExecutable(EngineSettings settings) {
    if (settings.useSystemExecutable) {
      return switch (settings.engineType) {
        EngineType.ytDlp => 'yt-dlp',
        EngineType.youtubeDl => 'youtube-dl',
        EngineType.custom => settings.executablePath.trim().isEmpty
            ? null
            : settings.executablePath.trim(),
      };
    }

    final customPath = settings.executablePath.trim();
    if (customPath.isEmpty) return null;
    return customPath;
  }
}
