enum OutputFolderType { downloads, videos, documents, custom }

class OutputFolderChoice {
  final OutputFolderType type;
  final String label;
  final String? customPath;

  const OutputFolderChoice({
    required this.type,
    required this.label,
    this.customPath,
  });

  static const OutputFolderChoice downloads = OutputFolderChoice(
    type: OutputFolderType.downloads,
    label: 'Downloads',
  );

  OutputFolderChoice copyWith({
    OutputFolderType? type,
    String? label,
    String? customPath,
  }) {
    return OutputFolderChoice(
      type: type ?? this.type,
      label: label ?? this.label,
      customPath: customPath ?? this.customPath,
    );
  }
}
