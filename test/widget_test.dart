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

    // Advance each asynchronous splash stage separately. A single large
    // pump can finish the animation while its async continuation only then
    // creates the next Future.delayed timer, leaving that timer pending when
    // the test disposes the widget tree.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pumpAndSettle();

    final homeVisible = find.byKey(const Key('manox-home-logo')).evaluate().isNotEmpty;
    final loginVisible = find.byType(LoginPage).evaluate().isNotEmpty;
    expect(homeVisible || loginVisible, isTrue,
        reason: 'App should complete splash and reach either Home or Login.');
  });
}
