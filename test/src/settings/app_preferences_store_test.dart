import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clipflow_downloader/src/settings/app_preferences.dart';
import 'package:clipflow_downloader/src/settings/app_preferences_store.dart';
import 'package:clipflow_downloader/src/settings/output_folder_choice.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('load sem dados retorna defaults', () async {
    final store = AppPreferencesStore();
    final prefs = await store.load();

    expect(prefs.smartModeEnabled, AppPreferences.defaults.smartModeEnabled);
    expect(
      prefs.simultaneousDownloads,
      AppPreferences.defaults.simultaneousDownloads,
    );
    expect(
      prefs.useFirefoxCookiesForYouTube,
      AppPreferences.defaults.useFirefoxCookiesForYouTube,
    );
    expect(prefs.outputFolderChoice.type, OutputFolderType.downloads);
    expect(prefs.outputFolderChoice.label, 'Downloads');
    expect(prefs.outputFolderChoice.customPath, isNull);
  });

  test('save/load preserva smartModeEnabled', () async {
    final store = AppPreferencesStore();
    await store.save(AppPreferences.defaults.copyWith(smartModeEnabled: true));
    final loaded = await store.load();

    expect(loaded.smartModeEnabled, isTrue);
  });

  test('save/load preserva useFirefoxCookiesForYouTube', () async {
    final store = AppPreferencesStore();
    await store.save(
      AppPreferences.defaults.copyWith(useFirefoxCookiesForYouTube: true),
    );
    final loaded = await store.load();

    expect(loaded.useFirefoxCookiesForYouTube, isTrue);
  });

  test('save/load preserva simultaneousDownloads', () async {
    final store = AppPreferencesStore();
    await store.save(
      AppPreferences.defaults.copyWith(simultaneousDownloads: 4),
    );
    final loaded = await store.load();

    expect(loaded.simultaneousDownloads, 4);
  });

  test('simultaneousDownloads inválido cai para default', () async {
    SharedPreferences.setMockInitialValues({
      'clipflow.simultaneousDownloads': 99,
    });
    final store = AppPreferencesStore();
    final loaded = await store.load();

    expect(
      loaded.simultaneousDownloads,
      AppPreferences.defaults.simultaneousDownloads,
    );
  });

  test(
    'save/load preserva OutputFolderChoice.custom com label e customPath',
    () async {
      final store = AppPreferencesStore();
      const customChoice = OutputFolderChoice(
        type: OutputFolderType.custom,
        label: 'Meus Downloads',
        customPath: r'C:\Users\test\Meus Downloads',
      );
      await store.save(
        AppPreferences.defaults.copyWith(outputFolderChoice: customChoice),
      );
      final loaded = await store.load();

      expect(loaded.outputFolderChoice.type, OutputFolderType.custom);
      expect(loaded.outputFolderChoice.label, 'Meus Downloads');
      expect(
        loaded.outputFolderChoice.customPath,
        r'C:\Users\test\Meus Downloads',
      );
    },
  );

  test('custom sem customPath cai para downloads', () async {
    SharedPreferences.setMockInitialValues({
      'clipflow.outputFolderType': 'custom',
      'clipflow.outputFolderLabel': 'Algo',
      // customPath ausente
    });
    final store = AppPreferencesStore();
    final loaded = await store.load();

    expect(loaded.outputFolderChoice.type, OutputFolderType.downloads);
  });

  test('outputFolderType desconhecido cai para downloads', () async {
    SharedPreferences.setMockInitialValues({
      'clipflow.outputFolderType': 'unknown_value',
    });
    final store = AppPreferencesStore();
    final loaded = await store.load();

    expect(loaded.outputFolderChoice.type, OutputFolderType.downloads);
  });

  test('save/load preserva notifyWhenDownloadCompletes', () async {
    final store = AppPreferencesStore();
    await store.save(
      AppPreferences.defaults.copyWith(notifyWhenDownloadCompletes: false),
    );
    final loaded = await store.load();

    expect(loaded.notifyWhenDownloadCompletes, isFalse);
  });

  test('load sem chave minimizeToTrayOnClose usa default true', () async {
    final store = AppPreferencesStore();
    final loaded = await store.load();

    expect(loaded.minimizeToTrayOnClose, isTrue);
  });

  test('save/load preserva minimizeToTrayOnClose false', () async {
    final store = AppPreferencesStore();
    await store.save(
      AppPreferences.defaults.copyWith(minimizeToTrayOnClose: false),
    );
    final loaded = await store.load();

    expect(loaded.minimizeToTrayOnClose, isFalse);
  });
}
