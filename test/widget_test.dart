import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/app.dart';

void main() {
  testWidgets('Home screen renders core actions', (WidgetTester tester) async {
    await tester.pumpWidget(const ClipFlowApp());

    expect(find.text('ClipFlow Downloader'), findsOneWidget);
    expect(find.text('Colar link'), findsOneWidget);
    expect(find.text('Sobre o motor'), findsOneWidget);
    expect(find.text('Motor interno ativo'), findsOneWidget);
    expect(find.byTooltip('Remover'), findsWidgets);
    expect(find.byTooltip('Configurações'), findsOneWidget);
  });

  testWidgets('opens internal engine dialog from status bar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClipFlowApp());

    await tester.tap(find.text('Sobre o motor'));
    await tester.pump();

    expect(find.text('Motor interno'), findsOneWidget);
    expect(find.textContaining('yt-dlp/youtube-dl'), findsOneWidget);

    await tester.tap(find.text('Entendi'));
    await tester.pump();

    expect(find.text('Motor interno'), findsNothing);
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
