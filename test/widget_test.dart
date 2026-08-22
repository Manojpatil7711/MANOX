import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manox/main.dart';

void main() {
  testWidgets('ManoxApp builds and displays home page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ManoxApp());

    // Verify the app renders without errors
    expect(find.byType(MaterialApp), findsOneWidget);

    // Verify the home page is displayed
    expect(find.byType(ManoxHomePage), findsOneWidget);

    // Verify the app bar title
    expect(find.text('MANOX'), findsWidgets);

    // Verify the welcome message
    expect(find.text('Welcome to MANOX'), findsOneWidget);

    // Verify the tagline
    expect(find.text('Create. Connect. Grow.'), findsOneWidget);

    // Verify the global icon is displayed
    expect(find.byIcon(Icons.public), findsOneWidget);
  });
}
