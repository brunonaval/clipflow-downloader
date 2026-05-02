import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/app.dart';

void main() {
  testWidgets('Home screen renders main UI elements', (WidgetTester tester) async {
    await tester.pumpWidget(const ClipFlowApp());

    expect(find.text('ClipFlow Downloader'), findsOneWidget);
    expect(find.text('Colar link'), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Aula de violão — exemplo autorizado'), findsOneWidget);
    expect(find.text('Clipe independente — Creative Commons'), findsOneWidget);
    expect(find.text('Podcast próprio — episódio teste'), findsOneWidget);
    expect(find.text('Material de treino vocal — arquivo permitido'), findsOneWidget);
    expect(find.text('4 itens'), findsOneWidget);
    expect(find.text('Pronto para downloads autorizados'), findsOneWidget);
  });
}
