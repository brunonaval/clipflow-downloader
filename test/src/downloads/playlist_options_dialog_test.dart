import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/downloads/playlist_options_dialog.dart';
import 'package:clipflow_downloader/src/engine/yt_dlp/yt_dlp_playlist_result.dart';

void main() {
  const playlist = YtDlpPlaylistResult(
    title: 'Minha playlist',
    authorLabel: 'Canal Teste',
    entries: [
      YtDlpPlaylistEntry(
        id: 'dup',
        title: 'Video 1',
        url: 'https://www.youtube.com/watch?v=a1',
        durationLabel: '01:00',
        thumbnailUrl: 'https://i.ytimg.com/vi/a1/hqdefault.jpg',
      ),
      YtDlpPlaylistEntry(
        id: 'dup',
        title: 'Video 2',
        url: 'https://www.youtube.com/watch?v=a2',
      ),
      YtDlpPlaylistEntry(id: '', title: 'Private video', url: ''),
    ],
  );

  Future<void> openDialog(WidgetTester tester, Widget dialog) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    final context = tester.element(find.byType(Scaffold));
    showDialog<void>(context: context, builder: (_) => dialog);
    await tester.pumpAndSettle();
  }

  testWidgets('renderiza título e contador', (tester) async {
    await openDialog(tester, const PlaylistOptionsDialog(playlist: playlist));
    expect(find.text('Baixar playlist'), findsOneWidget);
    expect(find.text('Selecionados: 2 de 3'), findsOneWidget);
  });

  testWidgets('contador usa índice e não id único', (tester) async {
    await openDialog(tester, const PlaylistOptionsDialog(playlist: playlist));
    expect(find.text('Selecionados: 2 de 3'), findsOneWidget);
  });

  testWidgets('entrada indisponível aparece desabilitada', (tester) async {
    await openDialog(tester, const PlaylistOptionsDialog(playlist: playlist));
    expect(find.text('Indisponível'), findsOneWidget);
    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox).last);
    expect(checkbox.onChanged, isNull);
  });

  testWidgets('desmarcar item atualiza contador', (tester) async {
    await openDialog(tester, const PlaylistOptionsDialog(playlist: playlist));
    await tester.tap(find.byKey(const Key('playlist-entry-0')));
    await tester.pumpAndSettle();
    expect(find.text('Selecionados: 1 de 3'), findsOneWidget);
  });

  testWidgets('adicionar retorna entradas selecionadas na ordem', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    final context = tester.element(find.byType(Scaffold));
    List<YtDlpPlaylistEntry>? result;
    showDialog<List<YtDlpPlaylistEntry>>(
      context: context,
      builder: (_) => const PlaylistOptionsDialog(playlist: playlist),
    ).then((value) => result = value);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('playlist-entry-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar à fila'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!, hasLength(1));
    expect(result!.first.title, 'Video 2');
  });

  testWidgets('lista grande renderiza sem crash de Scrollbar', (tester) async {
    final entries = List<YtDlpPlaylistEntry>.generate(
      220,
      (i) => YtDlpPlaylistEntry(
        id: 'id-$i',
        title: 'Video $i',
        url: 'https://www.youtube.com/watch?v=id$i',
      ),
    );
    final large = YtDlpPlaylistResult(title: 'Grande', entries: entries);
    await openDialog(tester, PlaylistOptionsDialog(playlist: large));
    expect(find.byType(Scrollbar), findsOneWidget);
    expect(find.text('Selecionados: 220 de 220'), findsOneWidget);
  });
}
