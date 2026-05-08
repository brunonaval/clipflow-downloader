import 'package:shared_preferences/shared_preferences.dart';

import 'app_preferences.dart';
import 'output_folder_choice.dart';

class AppPreferencesStore {
  static const _kLanguageLabel = 'clipflow.languageLabel';
  static const _kThemeLabel = 'clipflow.themeLabel';
  static const _kOpenFolderWhenDone = 'clipflow.openFolderWhenDone';
  static const _kRemoveCompletedAutomatically =
      'clipflow.removeCompletedAutomatically';
  static const _kSimultaneousDownloads = 'clipflow.simultaneousDownloads';
  static const _kNotifyWhenDownloadCompletes =
      'clipflow.notifyWhenDownloadCompletes';
  static const _kNotifyWhenDownloadFails = 'clipflow.notifyWhenDownloadFails';
  static const _kConfirmExitWithActiveDownloads =
      'clipflow.confirmExitWithActiveDownloads';
  static const _kKeepSystemAwakeWhileDownloading =
      'clipflow.keepSystemAwakeWhileDownloading';
  static const _kShowAdvancedFormats = 'clipflow.showAdvancedFormats';
  static const _kSmartModeEnabled = 'clipflow.smartModeEnabled';
  static const _kUseFirefoxCookiesForYouTube =
      'clipflow.useFirefoxCookiesForYouTube';
  static const _kOutputFolderType = 'clipflow.outputFolderType';
  static const _kOutputFolderLabel = 'clipflow.outputFolderLabel';
  static const _kOutputFolderCustomPath = 'clipflow.outputFolderCustomPath';
  static const _kMinimizeToTrayOnClose = 'clipflow.minimizeToTrayOnClose';

  Future<AppPreferences> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final d = AppPreferences.defaults;

      int simultaneous =
          prefs.getInt(_kSimultaneousDownloads) ?? d.simultaneousDownloads;
      if (!AppPreferences.allowedSimultaneousDownloads.contains(simultaneous)) {
        simultaneous = d.simultaneousDownloads;
      }

      return AppPreferences(
        languageLabel: prefs.getString(_kLanguageLabel) ?? d.languageLabel,
        themeLabel: prefs.getString(_kThemeLabel) ?? d.themeLabel,
        openFolderWhenDone:
            prefs.getBool(_kOpenFolderWhenDone) ?? d.openFolderWhenDone,
        removeCompletedAutomatically:
            prefs.getBool(_kRemoveCompletedAutomatically) ??
            d.removeCompletedAutomatically,
        simultaneousDownloads: simultaneous,
        notifyWhenDownloadCompletes:
            prefs.getBool(_kNotifyWhenDownloadCompletes) ??
            d.notifyWhenDownloadCompletes,
        notifyWhenDownloadFails:
            prefs.getBool(_kNotifyWhenDownloadFails) ??
            d.notifyWhenDownloadFails,
        confirmExitWithActiveDownloads:
            prefs.getBool(_kConfirmExitWithActiveDownloads) ??
            d.confirmExitWithActiveDownloads,
        keepSystemAwakeWhileDownloading:
            prefs.getBool(_kKeepSystemAwakeWhileDownloading) ??
            d.keepSystemAwakeWhileDownloading,
        showAdvancedFormats:
            prefs.getBool(_kShowAdvancedFormats) ?? d.showAdvancedFormats,
        smartModeEnabled:
            prefs.getBool(_kSmartModeEnabled) ?? d.smartModeEnabled,
        useFirefoxCookiesForYouTube:
            prefs.getBool(_kUseFirefoxCookiesForYouTube) ??
            d.useFirefoxCookiesForYouTube,
        outputFolderChoice: _loadOutputFolderChoice(prefs),
        minimizeToTrayOnClose:
            prefs.getBool(_kMinimizeToTrayOnClose) ?? d.minimizeToTrayOnClose,
      );
    } catch (_) {
      return AppPreferences.defaults;
    }
  }

  Future<void> save(AppPreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLanguageLabel, preferences.languageLabel);
      await prefs.setString(_kThemeLabel, preferences.themeLabel);
      await prefs.setBool(_kOpenFolderWhenDone, preferences.openFolderWhenDone);
      await prefs.setBool(
        _kRemoveCompletedAutomatically,
        preferences.removeCompletedAutomatically,
      );
      await prefs.setInt(
        _kSimultaneousDownloads,
        preferences.simultaneousDownloads,
      );
      await prefs.setBool(
        _kNotifyWhenDownloadCompletes,
        preferences.notifyWhenDownloadCompletes,
      );
      await prefs.setBool(
        _kNotifyWhenDownloadFails,
        preferences.notifyWhenDownloadFails,
      );
      await prefs.setBool(
        _kConfirmExitWithActiveDownloads,
        preferences.confirmExitWithActiveDownloads,
      );
      await prefs.setBool(
        _kKeepSystemAwakeWhileDownloading,
        preferences.keepSystemAwakeWhileDownloading,
      );
      await prefs.setBool(
        _kShowAdvancedFormats,
        preferences.showAdvancedFormats,
      );
      await prefs.setBool(_kSmartModeEnabled, preferences.smartModeEnabled);
      await prefs.setBool(
        _kUseFirefoxCookiesForYouTube,
        preferences.useFirefoxCookiesForYouTube,
      );
      await _saveOutputFolderChoice(prefs, preferences.outputFolderChoice);
      await prefs.setBool(
        _kMinimizeToTrayOnClose,
        preferences.minimizeToTrayOnClose,
      );
    } catch (_) {}
  }

  OutputFolderChoice _loadOutputFolderChoice(SharedPreferences prefs) {
    final typeStr = prefs.getString(_kOutputFolderType);
    final label = prefs.getString(_kOutputFolderLabel);
    final customPath = prefs.getString(_kOutputFolderCustomPath);

    final type = switch (typeStr) {
      'videos' => OutputFolderType.videos,
      'documents' => OutputFolderType.documents,
      'custom' => OutputFolderType.custom,
      _ => OutputFolderType.downloads,
    };

    if (type == OutputFolderType.custom &&
        (customPath == null || customPath.trim().isEmpty)) {
      return OutputFolderChoice.downloads;
    }

    final defaultLabel = _defaultLabelFor(type);
    return OutputFolderChoice(
      type: type,
      label: (label != null && label.isNotEmpty) ? label : defaultLabel,
      customPath: customPath,
    );
  }

  Future<void> _saveOutputFolderChoice(
    SharedPreferences prefs,
    OutputFolderChoice choice,
  ) async {
    final typeStr = switch (choice.type) {
      OutputFolderType.videos => 'videos',
      OutputFolderType.documents => 'documents',
      OutputFolderType.custom => 'custom',
      OutputFolderType.downloads => 'downloads',
    };
    await prefs.setString(_kOutputFolderType, typeStr);
    await prefs.setString(_kOutputFolderLabel, choice.label);
    if (choice.customPath != null) {
      await prefs.setString(_kOutputFolderCustomPath, choice.customPath!);
    } else {
      await prefs.remove(_kOutputFolderCustomPath);
    }
  }

  String _defaultLabelFor(OutputFolderType type) => switch (type) {
    OutputFolderType.videos => 'Vídeos',
    OutputFolderType.documents => 'Documentos',
    OutputFolderType.custom => 'Pasta escolhida',
    OutputFolderType.downloads => 'Downloads',
  };
}
