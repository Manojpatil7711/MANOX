import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:manox/features/profile/presentation/profile_page.dart';
import 'package:manox/core/theme/theme.dart';

void main() {
  testWidgets('ProfilePage renders and shows basic info', (WidgetTester tester) async {
    // narrow
    final binding = tester.binding;
    binding.window.devicePixelRatioTestValue = 1.0;
    binding.window.physicalSizeTestValue = const Size(375, 800);

    addTearDown(() {
      binding.window.clearDevicePixelRatioTestValue();
      binding.window.clearPhysicalSizeTestValue();
    });

    await tester.pumpWidget(const MaterialApp(home: ProfilePage(), theme: manoxTheme()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-avatar')), findsOneWidget);
    expect(find.byKey(const Key('profile-name')), findsOneWidget);
    expect(find.byKey(const Key('profile-handle')), findsOneWidget);
    expect(find.byKey(const Key('profile-bio')), findsOneWidget);
    expect(find.byKey(const Key('profile-edit-button')), findsOneWidget);
    expect(find.byKey(const Key('profile-settings-button')), findsOneWidget);

    // posts empty state (demo profile uses two posts so adjust expectation accordingly)
    // If posts exist, PostCard widgets should render; otherwise empty card.
    // We simply ensure no exceptions and layout OK on narrow.
  });
}
