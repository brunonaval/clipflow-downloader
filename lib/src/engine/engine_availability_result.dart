enum EngineAvailabilityStatus {
  unknown,
  available,
  unavailable,
}

class EngineAvailabilityResult {
  final EngineAvailabilityStatus status;
  final String executableLabel;
  final String? versionLabel;
  final String message;

  const EngineAvailabilityResult({
    required this.status,
    required this.executableLabel,
    this.versionLabel,
    required this.message,
  });

  bool get isAvailable => status == EngineAvailabilityStatus.available;

  static EngineAvailabilityResult unknown(String executableLabel) {
    return EngineAvailabilityResult(
      status: EngineAvailabilityStatus.unknown,
      executableLabel: executableLabel,
      message: 'Estado de verificação desconhecido',
    );
  }

  static EngineAvailabilityResult available({
    required String executableLabel,
    required String versionLabel,
  }) {
    return EngineAvailabilityResult(
      status: EngineAvailabilityStatus.available,
      executableLabel: executableLabel,
      versionLabel: versionLabel,
      message: 'Motor disponível',
    );
  }

  static EngineAvailabilityResult unavailable({
    required String executableLabel,
    required String message,
  }) {
    return EngineAvailabilityResult(
      status: EngineAvailabilityStatus.unavailable,
      executableLabel: executableLabel,
      message: message,
    );
  }
}
