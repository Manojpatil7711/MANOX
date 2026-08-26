import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:manox/features/home/data/demo_posts.dart';
import 'package:manox/features/home/presentation/home_page.dart';
import 'package:manox/core/theme/theme.dart';

void main() {
  testWidgets(
    'HomePage renders and feed interactions work',
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
      expect(find.text('Create a post…'), findsOneWidget);
      expect(demoPosts, isNotEmpty);

      final first = demoPosts.first;
      final card = find.byKey(Key('post-card-${first.id}'));
      final like = find.byKey(Key('post-like-${first.id}'));

      expect(card, findsOneWidget);
      expect(like, findsOneWidget);
      expect(find.text('${first.likes}'), findsWidgets);

      await tester.scrollUntilVisible(
        like,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(like);
      await tester.pumpAndSettle();

      expect(find.text('${first.likes + 1}'), findsWidgets);
    },
  );
}
