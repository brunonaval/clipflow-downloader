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
      ),
      YtDlpPlaylistEntry(
        id: 'b2',
        title: 'Video 2',
        url: 'https://www.youtube.com/watch?v=b2',
      ),
    ],
  );

  Future<T?> openDialog<T>(WidgetTester tester, Widget dialog) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    final context = tester.element(find.byType(Scaffold));
    showDialog<T>(context: context, builder: (_) => dialog);
    await tester.pumpAndSettle();
    return null;
  }

  testWidgets('renders playlist dialog title and header', (tester) async {
    await openDialog(tester, const PlaylistOptionsDialog(playlist: playlist));
    expect(find.text('Baixar playlist'), findsOneWidget);
    expect(find.text('Minha playlist'), findsOneWidget);
    expect(find.text('Canal Teste'), findsOneWidget);
  });

  testWidgets('all entries selected by default', (tester) async {
    await openDialog(tester, const PlaylistOptionsDialog(playlist: playlist));
    expect(
      tester
          .widget<CheckboxListTile>(find.byKey(const Key('playlist-entry-a1')))
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<CheckboxListTile>(find.byKey(const Key('playlist-entry-b2')))
          .value,
      isTrue,
    );
  });

  testWidgets('uncheck entry reduces selection', (tester) async {
    await openDialog(tester, const PlaylistOptionsDialog(playlist: playlist));
    await tester.tap(find.byKey(const Key('playlist-entry-a1')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CheckboxListTile>(find.byKey(const Key('playlist-entry-a1')))
          .value,
      isFalse,
    );
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
}
