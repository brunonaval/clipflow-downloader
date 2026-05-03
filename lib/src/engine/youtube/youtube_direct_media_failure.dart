import 'youtube_direct_media_locator.dart';

enum YouTubeDirectMediaFailureReason {
  formatNotFound,
  requiresSignature,
  noDirectUrl,
  invalidUrl,
  unsupported,
}

class YouTubeDirectMediaFailure {
  final YouTubeDirectMediaFailureReason reason;
  final String message;

  const YouTubeDirectMediaFailure({
    required this.reason,
    required this.message,
  });
}

class YouTubeDirectMediaLookupResult {
  final YouTubeDirectMediaReference? reference;
  final YouTubeDirectMediaFailure? failure;

  const YouTubeDirectMediaLookupResult.reference(this.reference)
    : failure = null;

  const YouTubeDirectMediaLookupResult.failure(this.failure) : reference = null;

  bool get hasReference => reference != null;
}
