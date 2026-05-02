import '../downloads/download_format_option.dart';
import 'engine_analysis_result.dart';

class MockEngineService {
  const MockEngineService();

  EngineAnalysisResult analyzeMockUrl({
    String? sourceUrl,
    String outputFolderLabel = 'Vídeos',
  }) {
    final hasUrl = sourceUrl != null && sourceUrl.trim().isNotEmpty;
    return EngineAnalysisResult(
      title: hasUrl ? 'Link autorizado analisado' : 'Novo link autorizado',
      durationLabel: '03:21',
      sourceLabel: 'Análise mockada concluída · $outputFolderLabel',
      formats: const [
        DownloadFormatOption(
          id: 'video-mp4-1080p',
          kind: DownloadFormatKind.video,
          label: 'Vídeo MP4 1080p',
          formatLabel: 'MP4',
          qualityLabel: '1080p',
          sizeLabel: '24 MB',
          detailsLabel: 'Vídeo com áudio em MP4',
          isRecommended: true,
        ),
        DownloadFormatOption(
          id: 'video-mp4-720p',
          kind: DownloadFormatKind.video,
          label: 'Vídeo MP4 720p',
          formatLabel: 'MP4',
          qualityLabel: '720p',
          sizeLabel: '16 MB',
          detailsLabel: 'Arquivo menor em MP4',
        ),
        DownloadFormatOption(
          id: 'audio-m4a',
          kind: DownloadFormatKind.audio,
          label: 'Áudio M4A',
          formatLabel: 'M4A',
          qualityLabel: 'Áudio',
          sizeLabel: '5 MB',
          detailsLabel: 'Somente áudio',
        ),
        DownloadFormatOption(
          id: 'subtitles-srt',
          kind: DownloadFormatKind.subtitles,
          label: 'Legendas SRT',
          formatLabel: 'SRT',
          qualityLabel: 'Texto',
          sizeLabel: '120 KB',
          detailsLabel: 'Legendas mockadas',
        ),
      ],
      recommendedFormatId: 'video-mp4-1080p',
    );
  }
}
