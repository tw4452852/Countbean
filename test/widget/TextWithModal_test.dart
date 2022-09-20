import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:countbean/add.dart' show TextWithModal;

void main() {
  testWidgets('TextWithModal', (tester) async {
    String got = "";
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: TextWithModal(
        name: 'test',
        suggestions: ['1', '2'],
        onsave: (v) => got = v,
      )),
    ));

    expect(find.text('<test>'), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);

    await tester.tap(find.text('<test>'));
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNWidgets(2));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
    expect(got, '1');

    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    expect(got, '2');
  });
}
