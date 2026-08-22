import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:manox/app.dart';

void main() {
  testWidgets('App boots and shows MANOX home key', (WidgetTester tester) async {
    await tester.pumpWidget(const ManoxApp());
    await tester.pumpAndSettle();
    // The home page includes a key on the main icon to make the test stable.
    expect(find.byKey(const Key('manox-home-logo')), findsOneWidget);
  });
}
