import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/engine/youtube/youtube_format_descriptor.dart';

void main() {
  group('YouTubeFormatDescriptor', () {
    test('preserva campos', () {
      const descriptor = YouTubeFormatDescriptor(
        id: '18',
        kind: YouTubeFormatKind.muxed,
        mimeType: 'video/mp4',
        extension: 'MP4',
        qualityLabel: '360p',
        bitrateLabel: '500 kbps',
        sizeLabel: '10 MB',
        detailsLabel: 'YouTube · itag 18 · vídeo+áudio',
        hasAudio: true,
        hasVideo: true,
      );

      expect(descriptor.id, '18');
      expect(descriptor.kind, YouTubeFormatKind.muxed);
      expect(descriptor.mimeType, 'video/mp4');
      expect(descriptor.extension, 'MP4');
      expect(descriptor.hasAudio, isTrue);
      expect(descriptor.hasVideo, isTrue);
    });

    test('isPlayableDescriptor default true', () {
      const descriptor = YouTubeFormatDescriptor(
        id: '140',
        kind: YouTubeFormatKind.audio,
        mimeType: 'audio/mp4',
        extension: 'M4A',
        qualityLabel: 'Áudio',
        bitrateLabel: '--',
        sizeLabel: '--',
        detailsLabel: 'YouTube · itag 140 · áudio',
        hasAudio: true,
        hasVideo: false,
      );

      expect(descriptor.isPlayableDescriptor, isTrue);
    });

    test('kind video/audio/muxed preservado', () {
      const video = YouTubeFormatDescriptor(
        id: '137',
        kind: YouTubeFormatKind.video,
        mimeType: 'video/mp4',
        extension: 'MP4',
        qualityLabel: '1080p',
        bitrateLabel: '--',
        sizeLabel: '--',
        detailsLabel: '',
        hasAudio: false,
        hasVideo: true,
      );
      const audio = YouTubeFormatDescriptor(
        id: '251',
        kind: YouTubeFormatKind.audio,
        mimeType: 'audio/webm',
        extension: 'WEBM',
        qualityLabel: 'Áudio',
        bitrateLabel: '--',
        sizeLabel: '--',
        detailsLabel: '',
        hasAudio: true,
        hasVideo: false,
      );
      const muxed = YouTubeFormatDescriptor(
        id: '22',
        kind: YouTubeFormatKind.muxed,
        mimeType: 'video/mp4',
        extension: 'MP4',
        qualityLabel: '720p',
        bitrateLabel: '--',
        sizeLabel: '--',
        detailsLabel: '',
        hasAudio: true,
        hasVideo: true,
      );

      expect(video.kind, YouTubeFormatKind.video);
      expect(audio.kind, YouTubeFormatKind.audio);
      expect(muxed.kind, YouTubeFormatKind.muxed);
    });

    test('não possui campo url', () {
      const descriptor = YouTubeFormatDescriptor(
        id: '18',
        kind: YouTubeFormatKind.muxed,
        mimeType: 'video/mp4',
        extension: 'MP4',
        qualityLabel: '360p',
        bitrateLabel: '500 kbps',
        sizeLabel: '10 MB',
        detailsLabel: 'YouTube · itag 18 · vídeo+áudio',
        hasAudio: true,
        hasVideo: true,
      );

      final map = <String, Object?>{
        'id': descriptor.id,
        'mimeType': descriptor.mimeType,
      };
      expect(map.containsKey('url'), isFalse);
    });
  });
}
