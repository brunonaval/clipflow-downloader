enum DownloadQueueFilter {
  all,
  video,
  audio,
  playlists,
  channels,
  subscriptions,
  ai,
}

extension DownloadQueueFilterLabels on DownloadQueueFilter {
  String get label => switch (this) {
    DownloadQueueFilter.all => 'Todos',
    DownloadQueueFilter.video => 'V\u00eddeo',
    DownloadQueueFilter.audio => '\u00c1udio',
    DownloadQueueFilter.playlists => 'Listas de Reprodu\u00e7\u00e3o',
    DownloadQueueFilter.channels => 'Canais',
    DownloadQueueFilter.subscriptions => 'Assinaturas',
    DownloadQueueFilter.ai => 'IA',
  };
}
