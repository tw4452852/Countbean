import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:countbean/add.dart' show Chips;

void main() {
  testWidgets('Chips', (tester) async {
    final List<String> got = [];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: Chips(
        name: 'test',
        suggestions: ['1', '2'],
        result: got,
      )),
    ));

    expect(find.text('test:'), findsOneWidget);
    expect(find.byType(ActionChip), findsNWidgets(2));

    await tester.tap(find.text('1'));
    await tester.pump();
    expect(got, equals(['1']));

    await tester.tap(find.byType(IconButton));
    await tester.pump();
    await tester.tap(find.text('CANCEL'));
    await tester.pump();
    expect(got, equals(['1']));

    await tester.tap(find.byType(IconButton));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '3');
    await tester.tap(find.text('OK'));
    await tester.pump();
    expect(got, equals(['1', '3']));

    await tester.tap(find.descendant(
      of: find.widgetWithText(Chip, '3'),
      matching: find.byIcon(Icons.cancel),
    ));
    await tester.pump();
    expect(got, equals(['1']));
  });
}
