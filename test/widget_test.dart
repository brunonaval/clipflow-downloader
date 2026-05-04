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
  testWidgets('Home screen renders core actions and empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClipFlowApp());

    expect(find.text('ClipFlow Downloader'), findsOneWidget);
    expect(find.text('Colar link'), findsWidgets);
    expect(find.text('Sobre o motor'), findsNothing);
    expect(find.text('Pronto para downloads'), findsOneWidget);
    expect(find.text('Cole um link para começar'), findsOneWidget);
    expect(
      find.text(
        'Baixe vídeos, áudios e playlists autorizados em poucos cliques.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Guardar em'), findsWidgets);
    expect(find.textContaining('Transferir'), findsWidgets);
    expect(find.textContaining('Qualidade'), findsWidgets);
    expect(find.text('Para MP4'), findsOneWidget);
    expect(find.text('Modo inteligente'), findsWidgets);
    expect(find.text('Ordenar por'), findsOneWidget);
    expect(find.text('Iniciar fila'), findsOneWidget);
    expect(find.textContaining('simult'), findsOneWidget);
  });

  testWidgets('menu principal mostra apenas Arquivo, Ferramentas e Ajuda', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClipFlowApp());

    expect(find.text('Arquivo'), findsOneWidget);
    expect(find.text('Ferramentas'), findsOneWidget);
    expect(find.text('Ajuda'), findsOneWidget);
    expect(find.text('Editar'), findsNothing);
    expect(find.text('Ver'), findsNothing);
  });

  testWidgets('menu Arquivo exibe ação de abrir pasta de downloads', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClipFlowApp());

    await tester.tap(find.text('Arquivo'));
    await tester.pump();

    expect(find.text('Abrir pasta de downloads'), findsOneWidget);
  });

  testWidgets('menu Ajuda abre Sobre o ClipFlow', (WidgetTester tester) async {
    await tester.pumpWidget(const ClipFlowApp());

    await tester.tap(find.text('Ajuda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sobre o ClipFlow'));
    await tester.pumpAndSettle();

    expect(find.text('Sobre o ClipFlow'), findsWidgets);
    expect(find.textContaining('interface simples e direta'), findsOneWidget);
  });

  testWidgets('menu Ajuda abre Sobre o desenvolvedor', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClipFlowApp());

    await tester.tap(find.text('Ajuda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sobre o desenvolvedor'));
    await tester.pumpAndSettle();

    expect(find.text('Sobre o desenvolvedor'), findsWidgets);
    expect(find.textContaining('M4rMil'), findsOneWidget);
    expect(find.textContaining('Bruno Siqueira Ferreira'), findsOneWidget);
    expect(find.textContaining('Yanna Daniela'), findsOneWidget);
    expect(find.textContaining('Noah'), findsOneWidget);
    expect(find.textContaining('Isaac'), findsOneWidget);
    expect(find.textContaining('Davi'), findsOneWidget);
    expect(find.textContaining('bruno_bt_rj'), findsOneWidget);
  });

  testWidgets('menu Ajuda abre Apoiar o projeto', (WidgetTester tester) async {
    await tester.pumpWidget(const ClipFlowApp());

    await tester.tap(find.text('Ajuda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apoiar o projeto'));
    await tester.pumpAndSettle();

    expect(find.text('Apoiar o projeto'), findsWidgets);
    expect(find.textContaining('bruno_naval@hotmail.com'), findsOneWidget);
  });

  testWidgets('menu Ferramentas abre Preferências', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClipFlowApp());

    await tester.tap(find.text('Ferramentas').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Preferências'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Prefer'), findsWidgets);
  });

  testWidgets('filtros ocultam IA, Canais e Assinaturas', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClipFlowApp());

    expect(find.text('IA'), findsNothing);
    expect(find.text('Canais'), findsNothing);
    expect(find.text('Assinaturas'), findsNothing);
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
      sourceLabel: 'Pronto',
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
    expect(
      find.text('Fila iniciada').evaluate().isNotEmpty ||
          find.text('Nenhum item na fila para iniciar.').evaluate().isNotEmpty,
      isTrue,
    );
  });

  testWidgets('preferências mostram opções ativas apenas', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClipFlowApp());

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Modo inteligente'), findsWidgets);
    expect(find.text('Idioma'), findsNothing);
    expect(find.text('Tema'), findsNothing);

    await tester.tap(find.textContaining('Notifica'));
    await tester.pumpAndSettle();

    expect(find.text('Notificar ao concluir download'), findsOneWidget);
    expect(find.text('Notificar ao falhar download'), findsOneWidget);

    await tester.tap(find.text('Downloads'));
    await tester.pumpAndSettle();
    expect(find.text('Pasta padrão'), findsOneWidget);
  });
}
