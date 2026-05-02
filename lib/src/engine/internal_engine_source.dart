enum InternalEngineSourceKind {
  directFile,
  webpage,
  unsupported,
}

class InternalEngineSource {
  final Uri? uri;
  final InternalEngineSourceKind kind;
  final String label;

  const InternalEngineSource({
    required this.uri,
    required this.kind,
    required this.label,
  });
}
