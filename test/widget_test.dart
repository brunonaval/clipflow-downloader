import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/main.dart';

void main() {
  testWidgets('Home screen renders app title', (WidgetTester tester) async {
    await tester.pumpWidget(const ClipFlowApp());

    expect(find.text('ClipFlow Downloader'), findsWidgets);
    expect(find.text('Colar link'), findsOneWidget);
  });
}
