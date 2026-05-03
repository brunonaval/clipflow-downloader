import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/settings/output_folder_choice.dart';

void main() {
  test('default choice is downloads', () {
    const choice = OutputFolderChoice.downloads;

    expect(choice.type, OutputFolderType.downloads);
    expect(choice.label, 'Downloads');
    expect(choice.customPath, isNull);
  });

  test('copyWith updates fields', () {
    const initial = OutputFolderChoice.downloads;

    final updated = initial.copyWith(
      type: OutputFolderType.documents,
      label: 'Documentos',
      customPath: '/tmp/custom',
    );

    expect(updated.type, OutputFolderType.documents);
    expect(updated.label, 'Documentos');
    expect(updated.customPath, '/tmp/custom');
  });

  test('supports videos label', () {
    const choice = OutputFolderChoice(
      type: OutputFolderType.videos,
      label: 'Vídeos',
    );

    expect(choice.label, 'Vídeos');
  });
}
