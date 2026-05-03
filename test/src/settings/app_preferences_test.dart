import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/settings/app_preferences.dart';
import 'package:clipflow_downloader/src/settings/output_folder_choice.dart';

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
    expect(prefs.outputFolderChoice.type, OutputFolderType.downloads);
    expect(prefs.outputFolderChoice.label, 'Downloads');
  });

  test('copyWith updates selected values', () {
    const prefs = AppPreferences.defaults;

    final updated = prefs.copyWith(
      languageLabel: 'Português',
      themeLabel: 'Escuro',
      simultaneousDownloads: 3,
      showAdvancedFormats: true,
      outputFolderChoice: const OutputFolderChoice(
        type: OutputFolderType.videos,
        label: 'Vídeos',
      ),
    );

    expect(updated.languageLabel, 'Português');
    expect(updated.themeLabel, 'Escuro');
    expect(updated.simultaneousDownloads, 3);
    expect(updated.showAdvancedFormats, isTrue);
    expect(updated.outputFolderChoice.type, OutputFolderType.videos);
    expect(updated.outputFolderChoice.label, 'Vídeos');
    expect(
      updated.notifyWhenDownloadCompletes,
      prefs.notifyWhenDownloadCompletes,
    );
  });
}
