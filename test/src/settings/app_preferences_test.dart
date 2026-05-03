import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/settings/app_preferences.dart';

void main() {
  test('defaults are set as expected', () {
    const prefs = AppPreferences.defaults;

    expect(prefs.languageLabel, 'Sistema');
    expect(prefs.themeLabel, 'Sistema');
    expect(prefs.openFolderWhenDone, isFalse);
    expect(prefs.removeCompletedAutomatically, isFalse);
    expect(prefs.simultaneousDownloads, 1);
    expect(prefs.notifyWhenDownloadCompletes, isTrue);
    expect(prefs.notifyWhenDownloadFails, isTrue);
    expect(prefs.confirmExitWithActiveDownloads, isTrue);
    expect(prefs.keepSystemAwakeWhileDownloading, isFalse);
    expect(prefs.showAdvancedFormats, isFalse);
  });

  test('copyWith updates selected values', () {
    const prefs = AppPreferences.defaults;

    final updated = prefs.copyWith(
      languageLabel: 'Português',
      themeLabel: 'Escuro',
      simultaneousDownloads: 3,
      showAdvancedFormats: true,
    );

    expect(updated.languageLabel, 'Português');
    expect(updated.themeLabel, 'Escuro');
    expect(updated.simultaneousDownloads, 3);
    expect(updated.showAdvancedFormats, isTrue);
    expect(
      updated.notifyWhenDownloadCompletes,
      prefs.notifyWhenDownloadCompletes,
    );
  });
}
