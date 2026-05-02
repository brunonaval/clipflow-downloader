import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/app.dart';

void main() {
  testWidgets('Home screen renders main UI elements', (WidgetTester tester) async {
    await tester.pumpWidget(const ClipFlowApp());

    expect(find.text('ClipFlow Downloader'), findsOneWidget);
    expect(find.text('Colar link'), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Aula de violão — exemplo autorizado'), findsOneWidget);
    expect(find.text('Pronto para downloads autorizados'), findsOneWidget);
  });
}
