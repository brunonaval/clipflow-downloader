import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/app.dart';

void main() {
  testWidgets('Home screen renders core actions', (WidgetTester tester) async {
    await tester.pumpWidget(const ClipFlowApp());

    expect(find.text('ClipFlow Downloader'), findsOneWidget);
    expect(find.text('Colar link'), findsOneWidget);
    expect(find.text('Sobre o motor'), findsOneWidget);
    expect(find.text('Motor yt-dlp ativo para YouTube'), findsOneWidget);
    expect(find.byTooltip('Remover'), findsWidgets);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
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
}
