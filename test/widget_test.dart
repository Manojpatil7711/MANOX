import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manox/app.dart';
import 'package:manox/features/auth/presentation/login_page.dart';

void main() {
  testWidgets('App boots and completes splash transition', (WidgetTester tester) async {
    final view = tester.view;
    view.devicePixelRatio = 1.0;
    view.physicalSize = const Size(800, 1200);
    addTearDown(() {
      view.resetDevicePixelRatio();
      view.resetPhysicalSize();
    });

    await tester.pumpWidget(const ManoxApp());

    // Allow the splash animations and its navigation timer to complete.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    final homeVisible = find.byKey(const Key('manox-home-logo')).evaluate().isNotEmpty;
    final loginVisible = find.byType(LoginPage).evaluate().isNotEmpty;
    expect(homeVisible || loginVisible, isTrue,
        reason: 'App should complete splash and reach either Home or Login.');
  });
}
