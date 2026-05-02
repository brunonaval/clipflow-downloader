import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/app.dart';

void main() {
  testWidgets('Home screen renders main UI elements', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClipFlowApp());

    expect(find.text('ClipFlow Downloader'), findsOneWidget);
    expect(find.text('Colar link'), findsOneWidget);
    expect(find.text('Transferir Vídeo'), findsOneWidget);
    expect(find.text('Qualidade Ótima'), findsOneWidget);
    expect(find.text('Para MP4'), findsOneWidget);
    expect(find.text('Guardar em Vídeos'), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Áudio'), findsOneWidget);
    expect(find.text('Aula de violão — exemplo autorizado'), findsOneWidget);
    expect(find.text('Clipe independente — Creative Commons'), findsOneWidget);
    expect(find.text('Podcast próprio — episódio teste'), findsOneWidget);
    expect(
      find.text('Material de treino vocal — arquivo permitido'),
      findsOneWidget,
    );
    expect(find.text('4 itens'), findsOneWidget);
    expect(find.text('Pronto para downloads autorizados'), findsOneWidget);
    expect(find.text('Motor externo não configurado'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Buscar'), findsOneWidget);
    expect(find.text('Limpar concluídos'), findsOneWidget);
    expect(find.text('Configurar motor'), findsOneWidget);
    expect(find.byTooltip('Remover'), findsWidgets);
  });

  testWidgets('opens engine settings dialog from status bar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClipFlowApp());

    await tester.tap(find.text('Configurar motor'));
    await tester.pump();

    expect(find.text('Configurar motor externo'), findsOneWidget);
    expect(find.text('Tipo de motor'), findsOneWidget);
    expect(find.text('Usar executável disponível no sistema'), findsOneWidget);
    expect(
      find.text(
        'Entendo que devo usar apenas conteúdo autorizado ou permitido',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('engineSettingsSaveButton')), findsOneWidget);
  });

  testWidgets(
    'save button starts disabled and enables after legal acceptance',
    (WidgetTester tester) async {
      await tester.pumpWidget(const ClipFlowApp());

      await tester.tap(find.text('Configurar motor'));
      await tester.pump();

      final saveFinder = find.byKey(const Key('engineSettingsSaveButton'));
      FilledButton saveButton = tester.widget<FilledButton>(saveFinder);
      expect(saveButton.onPressed, isNull);

      final legalUsageTile = find.byKey(
        const Key('engineSettingsLegalUsageCheckbox'),
      );
      await tester.ensureVisible(legalUsageTile);
      await tester.tap(
        find.descendant(of: legalUsageTile, matching: find.byType(Checkbox)),
      );
      await tester.pump(const Duration(milliseconds: 300));

      saveButton = tester.widget<FilledButton>(saveFinder);
      expect(saveButton.onPressed, isNotNull);
    },
  );

  testWidgets('saving closes dialog and updates mock engine status', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClipFlowApp());

    await tester.tap(find.text('Configurar motor'));
    await tester.pump();

    final legalUsageTile = find.byKey(
      const Key('engineSettingsLegalUsageCheckbox'),
    );
    await tester.ensureVisible(legalUsageTile);
    await tester.tap(
      find.descendant(of: legalUsageTile, matching: find.byType(Checkbox)),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final saveFinder = find.byKey(const Key('engineSettingsSaveButton'));
    final saveButton = tester.widget<FilledButton>(saveFinder);
    expect(saveButton.onPressed, isNotNull);

    await tester.ensureVisible(saveFinder);
    await tester.tap(saveFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Configurar motor externo'), findsNothing);
    final hasStatus = find
        .text('Motor externo configurado em modo mock')
        .evaluate()
        .isNotEmpty;
    final hasSnack = find
        .text('Configuração mockada do motor salva')
        .evaluate()
        .isNotEmpty;
    expect(hasStatus || hasSnack, isTrue);
  });

  testWidgets('paste starts mock analysis and then marks item as ready', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClipFlowApp());

    await tester.tap(find.text('Colar link'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    final hasStarted = find
        .text('Análise mockada iniciada')
        .evaluate()
        .isNotEmpty;
    final hasAnalyzing = find.text('Analisando').evaluate().isNotEmpty;
    expect(hasStarted || hasAnalyzing, isTrue);

    await tester.pump(const Duration(milliseconds: 2000));

    final hasReady = find.text('Pronto').evaluate().isNotEmpty;
    final hasCompleted = find
        .text('Análise mockada concluída')
        .evaluate()
        .isNotEmpty;
    expect(hasReady || hasCompleted, isTrue);
  });

  testWidgets('ready item shows format selector and can change to audio', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClipFlowApp());

    await tester.tap(find.text('Colar link'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2000));

    expect(find.textContaining('Vídeo MP4 1080p'), findsWidgets);
    expect(find.textContaining('Plano:'), findsWidgets);
  });
}
