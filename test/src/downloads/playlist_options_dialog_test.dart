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
        id: 'a1',
        title: 'Video 1',
        url: 'https://www.youtube.com/watch?v=a1',
        durationLabel: '01:00',
        thumbnailUrl: 'https://i.ytimg.com/vi/a1/hqdefault.jpg',
      ),
      YtDlpPlaylistEntry(
        id: 'b2',
        title: 'Video 2',
        url: 'https://www.youtube.com/watch?v=b2',
      ),
    ],
  );

  Future<void> openDialog(WidgetTester tester, Widget dialog) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    final context = tester.element(find.byType(Scaffold));
    showDialog<void>(context: context, builder: (_) => dialog);
    await tester.pumpAndSettle();
  }

  testWidgets('renders playlist dialog title and header', (tester) async {
    await openDialog(tester, const PlaylistOptionsDialog(playlist: playlist));
    expect(find.text('Baixar playlist'), findsOneWidget);
    expect(find.text('Minha playlist'), findsOneWidget);
    expect(find.text('Canal Teste'), findsOneWidget);
  });

  testWidgets('shows selection counter', (tester) async {
    await openDialog(tester, const PlaylistOptionsDialog(playlist: playlist));
    expect(find.text('Selecionados: 2 de 2'), findsOneWidget);
  });

  testWidgets('uncheck entry updates selection counter', (tester) async {
    await openDialog(tester, const PlaylistOptionsDialog(playlist: playlist));
    await tester.tap(find.byKey(const Key('playlist-entry-a1')));
    await tester.pumpAndSettle();
    expect(find.text('Selecionados: 1 de 2'), findsOneWidget);
  });

  testWidgets('cancel returns null', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    final context = tester.element(find.byType(Scaffold));
    List<YtDlpPlaylistEntry>? result;
    showDialog<List<YtDlpPlaylistEntry>?>(
      context: context,
      builder: (_) => const PlaylistOptionsDialog(playlist: playlist),
    ).then((value) => result = value);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('add returns selected entries', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    final context = tester.element(find.byType(Scaffold));
    List<YtDlpPlaylistEntry>? result;
    showDialog<List<YtDlpPlaylistEntry>>(
      context: context,
      builder: (_) => const PlaylistOptionsDialog(playlist: playlist),
    ).then((value) => result = value);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('playlist-entry-b2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar à fila'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.length, 1);
    expect(result!.first.id, 'a1');
  });

  testWidgets('add disabled when none selected', (tester) async {
    await openDialog(tester, const PlaylistOptionsDialog(playlist: playlist));
    await tester.tap(find.byKey(const Key('playlist-entry-a1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('playlist-entry-b2')));
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('renders thumbnail when entry has thumbnailUrl', (tester) async {
    await openDialog(tester, const PlaylistOptionsDialog(playlist: playlist));
    expect(find.byKey(const Key('playlist-thumb-a1')), findsOneWidget);
  });

  testWidgets('renders fallback thumbnail when thumbnailUrl is null', (
    tester,
  ) async {
    await openDialog(tester, const PlaylistOptionsDialog(playlist: playlist));
    expect(find.byKey(const Key('playlist-thumb-fallback-b2')), findsOneWidget);
  });

  testWidgets('empty playlist shows friendly empty state and disabled add', (
    tester,
  ) async {
    const emptyPlaylist = YtDlpPlaylistResult(
      title: 'Playlist vazia',
      entries: [],
    );
    await openDialog(
      tester,
      const PlaylistOptionsDialog(playlist: emptyPlaylist),
    );

    expect(
      find.text('Nenhum vídeo encontrado nesta playlist.'),
      findsOneWidget,
    );
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });
}
