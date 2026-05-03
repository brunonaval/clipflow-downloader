import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/app.dart';
import 'package:clipflow_downloader/src/downloads/download_format_option.dart';
import 'package:clipflow_downloader/src/downloads/download_item.dart';
import 'package:clipflow_downloader/src/downloads/download_options.dart';
import 'package:clipflow_downloader/src/downloads/download_options_dialog.dart';
import 'package:clipflow_downloader/src/downloads/download_sort_option.dart';
import 'package:clipflow_downloader/src/downloads/playlist_options_dialog.dart';
import 'package:clipflow_downloader/src/engine/yt_dlp/yt_dlp_playlist_result.dart';

void main() {
  testWidgets('Home screen renders core actions', (WidgetTester tester) async {
    await tester.pumpWidget(const ClipFlowApp());

    expect(find.text('ClipFlow Downloader'), findsOneWidget);
    expect(find.text('Colar link'), findsOneWidget);
    expect(find.text('Sobre o motor'), findsOneWidget);
    expect(find.text('Motor yt-dlp ativo para YouTube'), findsOneWidget);
    expect(find.byTooltip('Remover'), findsWidgets);
    expect(find.text('Canal ClipFlow'), findsOneWidget);
    expect(find.textContaining('Pronto'), findsWidgets);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.textContaining('Guardar em'), findsWidgets);
    expect(find.textContaining('Transferir'), findsWidgets);
    expect(find.textContaining('Qualidade'), findsWidgets);
    expect(find.text('Para MP4'), findsOneWidget);
    expect(find.text('Modo inteligente'), findsOneWidget);
    expect(find.text('Ordenar por'), findsOneWidget);
    expect(find.text('Iniciar fila'), findsOneWidget);
    expect(find.textContaining('simult'), findsOneWidget);
  });

  testWidgets('menu Arquivo exibe ação de abrir pasta de downloads', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClipFlowApp());

    await tester.tap(find.text('Arquivo'));
    await tester.pump();

    expect(find.text('Abrir pasta de downloads'), findsOneWidget);
  });

  testWidgets('item concluído com outputPath exibe abrir arquivo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClipFlowApp());

    expect(find.byTooltip('Abrir arquivo'), findsOneWidget);
    expect(find.byTooltip('Abrir pasta'), findsNWidgets(2));
  });

  testWidgets('opens internal engine dialog from status bar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClipFlowApp());

    await tester.tap(find.text('Sobre o motor'));
    await tester.pump();

    expect(find.text('Motor interno'), findsOneWidget);
    expect(
      find.textContaining('Motor yt-dlp ativo para YouTube'),
      findsWidgets,
    );
    expect(find.textContaining('FFmpeg'), findsWidgets);

    await tester.tap(find.text('Entendi'));
    await tester.pump();

    expect(find.text('Motor interno'), findsNothing);
  });

  testWidgets('botão Configurações abre Preferências', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClipFlowApp());

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();

    expect(find.textContaining('Prefer'), findsWidgets);
    expect(find.text('Geral'), findsWidgets);
  });

  testWidgets('menu Ferramentas abre Preferências', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClipFlowApp());

    await tester.tap(find.text('Ferramentas').first);
    await tester.pumpAndSettle();

    final prefsMenuItem = find.descendant(
      of: find.byType(PopupMenuItem<String>),
      matching: find.textContaining('Prefer'),
    );
    await tester.tap(prefsMenuItem);
    await tester.pumpAndSettle();

    expect(find.textContaining('Prefer'), findsWidgets);
  });

  testWidgets('toolbar permite trocar Guardar em para Vídeos', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ClipFlowApp());

    await tester.tap(find.text('Guardar em Downloads'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Guardar em'), findsWidgets);
  });

  testWidgets('toggle de modo inteligente muda estado visual', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClipFlowApp());

    final smartModeSwitch = find.byType(Switch).first;
    expect(tester.widget<Switch>(smartModeSwitch).value, isFalse);

    await tester.tap(smartModeSwitch);
    await tester.pump();

    expect(tester.widget<Switch>(smartModeSwitch).value, isTrue);
  });

  testWidgets('controle de ordenação permite selecionar Nome', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClipFlowApp());

    await tester.tap(find.byType(DropdownButton<DownloadSortField>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nome').last);
    await tester.pumpAndSettle();

    expect(find.text('Buscar'), findsOneWidget);
  });

  testWidgets('dialogo Baixar vídeo renderiza sem quebrar', (
    WidgetTester tester,
  ) async {
    final item = DownloadItem(
      id: 'w-1',
      title: 'Teste',
      durationLabel: '01:00',
      sizeLabel: '10 MB',
      formatLabel: 'MP4',
      qualityLabel: '720p',
      fpsLabel: '30fps',
      sourceLabel: 'Análise yt-dlp concluída',
      status: DownloadStatus.ready,
      selectedFormatId: '18',
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
      ],
    );

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    final context = tester.element(find.byType(SizedBox));
    showDialog<void>(
      context: context,
      builder: (_) => DownloadOptionsDialog(
        item: item,
        initialOptions: const DownloadOptions(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Baixar v'), findsOneWidget);
  });

  testWidgets('dialogo Baixar playlist renderiza sem quebrar', (
    WidgetTester tester,
  ) async {
    const playlist = YtDlpPlaylistResult(
      title: 'Playlist de teste',
      entries: [
        YtDlpPlaylistEntry(
          id: 'v1',
          title: 'Video 1',
          url: 'https://www.youtube.com/watch?v=v1',
        ),
      ],
    );
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    final context = tester.element(find.byType(SizedBox));
    showDialog<void>(
      context: context,
      builder: (_) => const PlaylistOptionsDialog(playlist: playlist),
    );
    await tester.pumpAndSettle();

    expect(find.text('Baixar playlist'), findsOneWidget);
    expect(find.text('Selecionar todos'), findsOneWidget);
  });

  testWidgets('botão Iniciar fila aparece e pode ser acionado', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClipFlowApp());

    final startQueueButton = find.text('Iniciar fila');
    expect(startQueueButton, findsOneWidget);
    await tester.ensureVisible(startQueueButton);
    await tester.tap(startQueueButton, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Iniciar fila'), findsOneWidget);
  });
}
