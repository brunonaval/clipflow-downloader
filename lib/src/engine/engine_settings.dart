enum EngineType {
  ytDlp,
  youtubeDl,
  custom,
}

enum EngineSetupStatus {
  notConfigured,
  configuredMock,
}

class EngineSettings {
  final EngineType engineType;
  final bool useSystemExecutable;
  final String executablePath;
  final bool acceptedLegalUsage;
  final EngineSetupStatus status;

  const EngineSettings({
    this.engineType = EngineType.ytDlp,
    this.useSystemExecutable = true,
    this.executablePath = '',
    this.acceptedLegalUsage = false,
    this.status = EngineSetupStatus.notConfigured,
  });

  EngineSettings copyWith({
    EngineType? engineType,
    bool? useSystemExecutable,
    String? executablePath,
    bool? acceptedLegalUsage,
    EngineSetupStatus? status,
  }) {
    return EngineSettings(
      engineType: engineType ?? this.engineType,
      useSystemExecutable: useSystemExecutable ?? this.useSystemExecutable,
      executablePath: executablePath ?? this.executablePath,
      acceptedLegalUsage: acceptedLegalUsage ?? this.acceptedLegalUsage,
      status: status ?? this.status,
    );
  }

  String get engineLabel => switch (engineType) {
        EngineType.ytDlp => 'yt-dlp',
        EngineType.youtubeDl => 'youtube-dl',
        EngineType.custom => 'Personalizado',
      };

  String get statusLabel => switch (status) {
        EngineSetupStatus.notConfigured => 'Motor não configurado',
        EngineSetupStatus.configuredMock => 'Configuração mockada salva',
      };

  bool get canSaveMockConfiguration {
    if (!acceptedLegalUsage) return false;
    if (useSystemExecutable) return true;
    return executablePath.trim().isNotEmpty;
  }
}
