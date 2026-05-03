class AppPreferences {
  final String languageLabel;
  final String themeLabel;
  final bool openFolderWhenDone;
  final bool removeCompletedAutomatically;
  final int simultaneousDownloads;
  final bool notifyWhenDownloadCompletes;
  final bool notifyWhenDownloadFails;
  final bool confirmExitWithActiveDownloads;
  final bool keepSystemAwakeWhileDownloading;
  final bool showAdvancedFormats;

  const AppPreferences({
    required this.languageLabel,
    required this.themeLabel,
    required this.openFolderWhenDone,
    required this.removeCompletedAutomatically,
    required this.simultaneousDownloads,
    required this.notifyWhenDownloadCompletes,
    required this.notifyWhenDownloadFails,
    required this.confirmExitWithActiveDownloads,
    required this.keepSystemAwakeWhileDownloading,
    required this.showAdvancedFormats,
  });

  static const AppPreferences defaults = AppPreferences(
    languageLabel: 'Sistema',
    themeLabel: 'Sistema',
    openFolderWhenDone: false,
    removeCompletedAutomatically: false,
    simultaneousDownloads: 1,
    notifyWhenDownloadCompletes: true,
    notifyWhenDownloadFails: true,
    confirmExitWithActiveDownloads: true,
    keepSystemAwakeWhileDownloading: false,
    showAdvancedFormats: false,
  );

  AppPreferences copyWith({
    String? languageLabel,
    String? themeLabel,
    bool? openFolderWhenDone,
    bool? removeCompletedAutomatically,
    int? simultaneousDownloads,
    bool? notifyWhenDownloadCompletes,
    bool? notifyWhenDownloadFails,
    bool? confirmExitWithActiveDownloads,
    bool? keepSystemAwakeWhileDownloading,
    bool? showAdvancedFormats,
  }) {
    return AppPreferences(
      languageLabel: languageLabel ?? this.languageLabel,
      themeLabel: themeLabel ?? this.themeLabel,
      openFolderWhenDone: openFolderWhenDone ?? this.openFolderWhenDone,
      removeCompletedAutomatically:
          removeCompletedAutomatically ?? this.removeCompletedAutomatically,
      simultaneousDownloads:
          simultaneousDownloads ?? this.simultaneousDownloads,
      notifyWhenDownloadCompletes:
          notifyWhenDownloadCompletes ?? this.notifyWhenDownloadCompletes,
      notifyWhenDownloadFails:
          notifyWhenDownloadFails ?? this.notifyWhenDownloadFails,
      confirmExitWithActiveDownloads:
          confirmExitWithActiveDownloads ?? this.confirmExitWithActiveDownloads,
      keepSystemAwakeWhileDownloading:
          keepSystemAwakeWhileDownloading ??
          this.keepSystemAwakeWhileDownloading,
      showAdvancedFormats: showAdvancedFormats ?? this.showAdvancedFormats,
    );
  }
}
