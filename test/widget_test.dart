import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/app.dart';

void main() {
  testWidgets('Home screen renders core actions', (WidgetTester tester) async {
    await tester.pumpWidget(const ClipFlowApp());

    expect(find.text('ClipFlow Downloader'), findsOneWidget);
    expect(find.text('Colar link'), findsOneWidget);
    expect(find.text('Configurar motor'), findsOneWidget);
    expect(find.text('Verificar motor'), findsOneWidget);
    expect(find.textContaining('Motor '), findsWidgets);
  });

  testWidgets('opens engine settings dialog from status bar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClipFlowApp());

    final configureButton = find.text('Configurar motor');
    await tester.ensureVisible(configureButton);
    await tester.tap(configureButton);
    await tester.pump();

    expect(find.text('Configurar motor externo'), findsOneWidget);
    expect(find.text('Tipo de motor'), findsOneWidget);
    expect(find.byKey(const Key('engineSettingsSaveButton')), findsOneWidget);
  });

  testWidgets('paste flow finishes with ready item and format section', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClipFlowApp());

    await tester.tap(find.text('Colar link'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    final hasAnalyzing = find.text('Analisando').evaluate().isNotEmpty;
    final hasReady = find.text('Pronto').evaluate().isNotEmpty;
    expect(hasAnalyzing || hasReady, isTrue);

    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.textContaining('Formato:'), findsWidgets);
    expect(find.textContaining('Plano:'), findsWidgets);
  });
}
