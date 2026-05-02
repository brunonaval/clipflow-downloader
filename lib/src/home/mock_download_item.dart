class MockDownloadItem {
  final String title;
  final String duration;
  final String size;
  final String format;
  final String resolution;
  final String fps;
  final String source;

  const MockDownloadItem({
    required this.title,
    required this.duration,
    required this.size,
    required this.format,
    required this.resolution,
    required this.fps,
    required this.source,
  });
}

const List<MockDownloadItem> kMockItems = [
  MockDownloadItem(
    title: 'Aula de violão — exemplo autorizado',
    duration: '03:03',
    size: '15,7 MB',
    format: 'MP4',
    resolution: '480p',
    fps: '25fps',
    source: 'Conteúdo autorizado',
  ),
  MockDownloadItem(
    title: 'Clipe independente — Creative Commons',
    duration: '03:03',
    size: '20,8 MB',
    format: 'MP4',
    resolution: '1080p',
    fps: '25fps',
    source: 'Creative Commons',
  ),
  MockDownloadItem(
    title: 'Podcast próprio — episódio teste',
    duration: '31:12',
    size: '96 MB',
    format: 'MP4',
    resolution: '720p',
    fps: '30fps',
    source: 'Conteúdo próprio',
  ),
  MockDownloadItem(
    title: 'Material de treino vocal — arquivo permitido',
    duration: '03:14',
    size: '9,3 MB',
    format: 'MP4',
    resolution: '1080p',
    fps: '30fps',
    source: 'Teste local',
  ),
];
