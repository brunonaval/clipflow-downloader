import 'output_folder_choice.dart';

class AppPreferences {
  static const List<int> allowedSimultaneousDownloads = [1, 2, 4, 6, 8];

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
  final bool smartModeEnabled;
  final bool useFirefoxCookiesForYouTube;
  final OutputFolderChoice outputFolderChoice;

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
    required this.smartModeEnabled,
    required this.useFirefoxCookiesForYouTube,
    required this.outputFolderChoice,
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
    smartModeEnabled: false,
    useFirefoxCookiesForYouTube: false,
    outputFolderChoice: OutputFolderChoice.downloads,
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
    bool? smartModeEnabled,
    bool? useFirefoxCookiesForYouTube,
    OutputFolderChoice? outputFolderChoice,
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
      smartModeEnabled: smartModeEnabled ?? this.smartModeEnabled,
      useFirefoxCookiesForYouTube:
          useFirefoxCookiesForYouTube ?? this.useFirefoxCookiesForYouTube,
      outputFolderChoice: outputFolderChoice ?? this.outputFolderChoice,
    );
  }

  static String simultaneousDownloadsRiskLabel(int value) {
    return switch (value) {
      1 || 2 => 'Seguro',
      4 => 'Estável',
      6 => 'Ideal',
      8 => 'Arriscado',
      _ => 'Seguro',
    };
  }
}
