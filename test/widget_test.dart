import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/app.dart';

void main() {
  testWidgets('Home screen renders main UI elements', (WidgetTester tester) async {
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
    expect(find.text('Material de treino vocal — arquivo permitido'), findsOneWidget);
    expect(find.text('4 itens'), findsOneWidget);
    expect(find.text('Pronto para downloads autorizados'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Buscar'), findsOneWidget);
    expect(find.text('Limpar concluídos'), findsOneWidget);
    expect(find.byTooltip('Remover'), findsWidgets);
  });
}
