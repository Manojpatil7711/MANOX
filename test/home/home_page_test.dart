import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:manox/features/home/data/demo_posts.dart';
import 'package:manox/features/home/presentation/home_page.dart';
import 'package:manox/core/theme/theme.dart';

void main() {
  testWidgets('HomePage renders and basic interactions work', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: manoxTheme(),
        home: const HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('manox-home-logo')), findsOneWidget);
    expect(find.byKey(const Key('post-composer-field')), findsOneWidget);
    expect(find.byKey(const Key('post-compose-submit')), findsOneWidget);

    expect(demoPosts, isNotEmpty);
    final first = demoPosts.first;
    final card = find.byKey(Key('post-card-${first.id}'));
    final like = find.byKey(Key('post-like-${first.id}'));

    expect(card, findsOneWidget);
    expect(like, findsOneWidget);
    expect(find.text('${first.likes}'), findsWidgets);

    // The first post is below the initial viewport on a narrow device, so
    // scroll it into view before tapping its like button.
    await tester.scrollUntilVisible(
      like,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(like);
    await tester.pump();

    expect(find.text('${first.likes + 1}'), findsWidgets);

    // Empty submission is intentionally ignored by HomePage.
    await tester.tap(find.byKey(const Key('post-compose-submit')));
    await tester.pump();
    expect(find.byKey(const Key('post-card-${first.id}')), findsOneWidget);
  });
}
