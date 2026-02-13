import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('minimal smoke test', (tester) async {
    runApp(const MaterialApp(home: Scaffold(body: Text('Hello'))));
    await tester.pumpAndSettle();
    expect(find.text('Hello'), findsOneWidget);
  });
}
