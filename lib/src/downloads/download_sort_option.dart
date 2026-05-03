enum DownloadSortField { added, title, status, type, author }

enum DownloadSortDirection { ascending, descending }

class DownloadSortOption {
  final DownloadSortField field;
  final DownloadSortDirection direction;

  const DownloadSortOption({required this.field, required this.direction});

  static const newestFirst = DownloadSortOption(
    field: DownloadSortField.added,
    direction: DownloadSortDirection.descending,
  );
}
