import 'download_format_option.dart';
import 'download_preset.dart';

class DownloadFormatSelector {
  const DownloadFormatSelector();

  String? selectRecommendedFormatId({
    required List<DownloadFormatOption> formats,
    required DownloadPreset preset,
  }) {
    if (formats.isEmpty) return null;

    if (preset.wantsSubtitles) {
      for (final format in formats) {
        if (format.kind == DownloadFormatKind.subtitles) {
          return format.id;
        }
      }
      return null;
    }

    if (preset.wantsAudioOnly) {
      return _selectAudioOnly(formats, preset);
    }

    if (preset.wantsVideo) {
      return _selectVideo(formats, preset);
    }

    return null;
  }

  String? _selectAudioOnly(
    List<DownloadFormatOption> formats,
    DownloadPreset preset,
  ) {
    final audioOnly = formats.where(_isAudioOnly).toList();
    if (audioOnly.isEmpty) return null;

    final preferredExt = preset.prefersWebm ? 'WEBM' : 'M4A';
    final preferred = audioOnly.where((f) => _ext(f) == preferredExt).toList();
    if (preferred.isNotEmpty) {
      return _bestByAudioScore(preferred).id;
    }

    if (!preset.prefersWebm) {
      final m4a = audioOnly.where((f) => _ext(f) == 'M4A').toList();
      if (m4a.isNotEmpty) return _bestByAudioScore(m4a).id;
      final webm = audioOnly.where((f) => _ext(f) == 'WEBM').toList();
      if (webm.isNotEmpty) return _bestByAudioScore(webm).id;
    }

    return _bestByAudioScore(audioOnly).id;
  }

  String? _selectVideo(
    List<DownloadFormatOption> formats,
    DownloadPreset preset,
  ) {
    final videos = formats.where(_isVideoCandidate).toList();
    if (videos.isEmpty) return null;

    final limited = _applyHeightPreference(videos, preset.maxHeight);

    if (preset.prefersMp4) {
      return _pickOrdered(limited, [
        (f) => _isMuxed(f) && _ext(f) == 'MP4',
        (f) => _isVideoOnly(f) && _ext(f) == 'MP4',
        (f) => _ext(f) == 'MP4' && _isVideoCandidate(f),
        (f) => _isMuxed(f) && _ext(f) == 'WEBM',
        (f) => _isVideoCandidate(f),
      ]);
    }

    if (preset.prefersWebm) {
      return _pickOrdered(limited, [
        (f) => _isMuxed(f) && _ext(f) == 'WEBM',
        (f) => _isVideoOnly(f) && _ext(f) == 'WEBM',
        (f) => _ext(f) == 'WEBM' && _isVideoCandidate(f),
        (f) => _isVideoCandidate(f),
      ]);
    }

    if (preset.prefersMkv || (!preset.prefersMp4 && !preset.prefersWebm)) {
      return _pickOrdered(limited, [
        (f) => _isMuxed(f) && _ext(f) == 'MP4',
        (f) => _isVideoOnly(f) && _ext(f) == 'MP4',
        (f) => _isMuxed(f) && _ext(f) == 'WEBM',
        (f) => _isVideoOnly(f) && _ext(f) == 'WEBM',
        (f) => _isVideoCandidate(f),
      ]);
    }

    return _pickOrdered(limited, [(f) => _isVideoCandidate(f)]);
  }

  List<DownloadFormatOption> _applyHeightPreference(
    List<DownloadFormatOption> formats,
    int? maxHeight,
  ) {
    if (maxHeight == null) return formats;

    final atOrBelow = formats.where((f) {
      final h = _heightFrom(f);
      return h != null && h <= maxHeight;
    }).toList();
    if (atOrBelow.isNotEmpty) return atOrBelow;

    final above = formats.where((f) {
      final h = _heightFrom(f);
      return h != null && h > maxHeight;
    }).toList();
    if (above.isEmpty) return formats;

    above.sort(
      (a, b) => (_heightFrom(a) ?? 99999).compareTo(_heightFrom(b) ?? 99999),
    );
    final smallest = _heightFrom(above.first);
    return above.where((f) => _heightFrom(f) == smallest).toList();
  }

  String? _pickOrdered(
    List<DownloadFormatOption> formats,
    List<bool Function(DownloadFormatOption)> groups,
  ) {
    for (final matcher in groups) {
      final candidates = formats.where(matcher).toList();
      if (candidates.isNotEmpty) {
        candidates.sort(_videoCompare);
        return candidates.first.id;
      }
    }
    return null;
  }

  int _videoCompare(DownloadFormatOption a, DownloadFormatOption b) {
    final ah = _heightFrom(a) ?? -1;
    final bh = _heightFrom(b) ?? -1;
    if (ah != bh) return bh.compareTo(ah);

    final ar = _videoRank(a);
    final br = _videoRank(b);
    if (ar != br) return ar.compareTo(br);

    return a.id.compareTo(b.id);
  }

  int _videoRank(DownloadFormatOption f) {
    if (_isMuxed(f) && _ext(f) == 'MP4') return 0;
    if (_isVideoOnly(f) && _ext(f) == 'MP4') return 1;
    if (_isMuxed(f) && _ext(f) == 'WEBM') return 2;
    if (_isVideoOnly(f) && _ext(f) == 'WEBM') return 3;
    return 4;
  }

  DownloadFormatOption _bestByAudioScore(List<DownloadFormatOption> formats) {
    final sorted = [...formats]
      ..sort((a, b) {
        final as = _audioScore(a);
        final bs = _audioScore(b);
        if (as != bs) return bs.compareTo(as);
        return a.id.compareTo(b.id);
      });
    return sorted.first;
  }

  int _audioScore(DownloadFormatOption option) {
    final match = RegExp(
      r'(\d{2,4})k',
    ).firstMatch(option.qualityLabel.toLowerCase());
    if (match == null) return 0;
    return int.tryParse(match.group(1) ?? '') ?? 0;
  }

  int? _heightFrom(DownloadFormatOption option) {
    final text = '${option.qualityLabel} ${option.label}'.toLowerCase();
    final match = RegExp(r'(\d{3,4})p').firstMatch(text);
    if (match == null) return null;
    return int.tryParse(match.group(1) ?? '');
  }

  bool _isMuxed(DownloadFormatOption option) {
    return option.detailsLabel.contains('[muxed]');
  }

  bool _isVideoOnly(DownloadFormatOption option) {
    return option.detailsLabel.contains('[video-only]');
  }

  bool _isAudioOnly(DownloadFormatOption option) {
    return option.kind == DownloadFormatKind.audio ||
        option.detailsLabel.contains('[audio-only]');
  }

  bool _isVideoCandidate(DownloadFormatOption option) {
    return option.kind == DownloadFormatKind.video ||
        _isMuxed(option) ||
        _isVideoOnly(option);
  }

  String _ext(DownloadFormatOption option) =>
      option.formatLabel.trim().toUpperCase();
}
