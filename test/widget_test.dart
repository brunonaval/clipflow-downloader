import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/app.dart';

void main() {
  testWidgets('Home screen renders main UI elements', (WidgetTester tester) async {
    await tester.pumpWidget(const ClipFlowApp());

    expect(find.text('Colar link'), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
  });
}
