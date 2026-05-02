enum YouTubeMediaCandidateKind { direct, requiresSignature, unavailable }

class YouTubeMediaCandidate {
  final String formatId;
  final YouTubeMediaCandidateKind kind;
  final String? safeHostLabel;
  final bool canAttemptDirectDownload;
  final String reasonLabel;

  const YouTubeMediaCandidate({
    required this.formatId,
    required this.kind,
    this.safeHostLabel,
    required this.canAttemptDirectDownload,
    required this.reasonLabel,
  });
}
