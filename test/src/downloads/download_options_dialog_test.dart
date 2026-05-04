import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/downloads/download_format_option.dart';
import 'package:clipflow_downloader/src/downloads/download_item.dart';
import 'package:clipflow_downloader/src/downloads/download_options.dart';
import 'package:clipflow_downloader/src/downloads/download_options_dialog.dart';
import 'package:clipflow_downloader/src/downloads/download_options_dialog_result.dart';

DownloadItem _item({String? selectedFormatId, String? authorLabel}) {
  return DownloadItem(
    id: 'yt-1',
    title: 'Video de teste',
    durationLabel: '03:21',
    sizeLabel: '10 MB',
    formatLabel: 'MP4',
    qualityLabel: '720p',
    fpsLabel: '30fps',
    sourceLabel: 'Pronto',
    status: DownloadStatus.ready,
    isYouTubeSource: true,
    selectedFormatId: selectedFormatId,
    authorLabel: authorLabel,
    availableFormats: const [
      DownloadFormatOption(
        id: '18',
        kind: DownloadFormatKind.video,
        label: 'Vídeo MP4 360p',
        formatLabel: 'MP4',
        qualityLabel: '360p',
        sizeLabel: '8 MB',
        detailsLabel: '[muxed] mp4',
      ),
      DownloadFormatOption(
        id: '137',
        kind: DownloadFormatKind.video,
        label: 'Vídeo sem áudio MP4 1080p',
        formatLabel: 'MP4',
        qualityLabel: '1080p',
        sizeLabel: '14 MB',
        detailsLabel: '[video-only] mp4',
        isRecommended: true,
      ),
      DownloadFormatOption(
        id: '140',
        kind: DownloadFormatKind.audio,
        label: 'Áudio M4A',
        formatLabel: 'M4A',
        qualityLabel: '128k',
        sizeLabel: '4 MB',
        detailsLabel: '[audio-only] m4a',
      ),
    ],
  );
}

Future<void> _openDialog(
  WidgetTester tester, {
  required DownloadItem item,
  DownloadOptions options = const DownloadOptions(),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => DownloadOptionsDialog(
                    item: item,
                    initialOptions: options,
                  ),
                );
              },
              child: const Text('Abrir'),
            );
          },
        ),
      ),
    ),
  );

  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renderiza título Baixar vídeo', (tester) async {
    await _openDialog(
      tester,
      item: _item(selectedFormatId: '18', authorLabel: 'Canal Teste'),
    );
    expect(find.text('Baixar vídeo'), findsOneWidget);
    expect(find.text('Opções'), findsOneWidget);
    expect(find.text('Formatos disponíveis'), findsOneWidget);
  });

  testWidgets('mostra título e autor quando existe', (tester) async {
    await _openDialog(
      tester,
      item: _item(selectedFormatId: '18', authorLabel: 'Canal Teste'),
    );
    expect(find.text('Video de teste'), findsOneWidget);
    expect(find.text('Canal Teste'), findsOneWidget);
  });

  testWidgets('mostra formatos em cards sem RadioListTile', (tester) async {
    await _openDialog(tester, item: _item(selectedFormatId: '18'));
    expect(find.byType(RadioListTile<String>), findsNothing);
    expect(find.byKey(const Key('manual-format-18')), findsOneWidget);
    expect(find.byKey(const Key('manual-format-137')), findsOneWidget);
    expect(find.text('Recomendado'), findsOneWidget);
  });

  testWidgets('seleção inicial usa item.selectedFormatId', (tester) async {
    await _openDialog(tester, item: _item(selectedFormatId: '18'));

    final selectedIcon = find.descendant(
      of: find.byKey(const Key('manual-format-18')),
      matching: find.byIcon(Icons.radio_button_checked),
    );
    expect(selectedIcon, findsOneWidget);
  });

  testWidgets('mudar qualidade para 1080p atualiza seleção recomendada', (
    tester,
  ) async {
    await _openDialog(tester, item: _item(selectedFormatId: '18'));

    await tester.tap(find.text('Ótima'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1080p').last);
    await tester.pumpAndSettle();

    final selectedIcon = find.descendant(
      of: find.byKey(const Key('manual-format-137')),
      matching: find.byIcon(Icons.radio_button_checked),
    );
    expect(selectedIcon, findsOneWidget);
  });

  testWidgets('clicar Cancelar fecha diálogo', (tester) async {
    await _openDialog(tester, item: _item(selectedFormatId: '18'));
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Baixar vídeo'), findsNothing);
  });

  testWidgets('clicar Baixar retorna DownloadOptionsDialogResult', (
    tester,
  ) async {
    DownloadOptionsDialogResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await showDialog<DownloadOptionsDialogResult>(
                    context: context,
                    builder: (_) => DownloadOptionsDialog(
                      item: _item(selectedFormatId: '18'),
                      initialOptions: const DownloadOptions(),
                    ),
                  );
                },
                child: const Text('Abrir'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Baixar'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.startDownload, isTrue);
    expect(result!.selectedFormatId, '18');
  });
}
