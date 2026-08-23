import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:manox/features/profile/presentation/profile_page.dart';
import 'package:manox/core/theme/theme.dart';

void main() {
  testWidgets('ProfilePage renders and shows basic info', (WidgetTester tester) async {
    // Use the current TestFlutterView API instead of the deprecated binding.window API.
    final view = tester.view;
    view.devicePixelRatio = 1.0;
    view.physicalSize = const Size(375, 800);

    addTearDown(() {
      view.resetDevicePixelRatio();
      view.resetPhysicalSize();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: const ProfilePage(),
        theme: manoxTheme(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-avatar')), findsOneWidget);
    expect(find.byKey(const Key('profile-name')), findsOneWidget);
    expect(find.byKey(const Key('profile-handle')), findsOneWidget);
    expect(find.byKey(const Key('profile-bio')), findsOneWidget);
    expect(find.byKey(const Key('profile-edit-button')), findsOneWidget);
    expect(find.byKey(const Key('profile-settings-button')), findsOneWidget);

    // Posts are not asserted here because the demo profile may render either
    // posts or an empty state. The test verifies the core profile layout.
  });
}
