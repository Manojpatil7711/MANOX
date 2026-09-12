import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:manox/features/home/presentation/home_page.dart';
import 'package:manox/core/theme/theme.dart';

void main() {
  testWidgets(
    'HomePage renders stable creator controls without requiring backend data',
    (WidgetTester tester) async {
      final view = tester.view;
      view.devicePixelRatio = 1.0;
      view.physicalSize = const Size(800, 1200);

      addTearDown(() {
        view.resetDevicePixelRatio();
        view.resetPhysicalSize();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: manoxTheme(),
          home: const HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('manox-home-logo')), findsOneWidget);
      expect(find.text('Share your world'), findsOneWidget);
      expect(find.text('For You'), findsOneWidget);
      expect(find.text('Following'), findsOneWidget);
      expect(find.text('Latest'), findsOneWidget);
      expect(find.byKey(const Key('home-profile-button')), findsOneWidget);

      await tester.tap(find.text('Latest'));
      await tester.pumpAndSettle();
      expect(find.text('Latest'), findsOneWidget);
    },
  );
}
