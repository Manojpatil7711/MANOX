import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:manox/features/home/presentation/home_page.dart';
import 'package:manox/features/home/data/demo_posts.dart';
import 'package:manox/core/theme/theme.dart';

void main() {
  testWidgets('HomePage renders and basic interactions work', (WidgetTester tester) async {
    // Narrow device simulation
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(MaterialApp(theme: manoxTheme(), home: const HomePage()));
    await tester.pumpAndSettle();

    // Logo exists
    expect(find.byKey(const Key('manox-home-logo')), findsOneWidget);

    // Composer exists
    expect(find.byKey(const Key('post-composer-field')), findsOneWidget);
    expect(find.byKey(const Key('post-compose-submit')), findsOneWidget);

    // Demo posts render
    expect(demoPosts.isNotEmpty, true);
    final first = demoPosts.first;
    expect(find.byKey(Key('post-card-${first.id}')), findsOneWidget);

    // Like button exists and toggles
    final likeFinder = find.byKey(Key('post-like-${first.id}'));
    expect(likeFinder, findsOneWidget);

    // initial likes text
    expect(find.text('${first.likes}'), findsWidgets);

    // tap like
    await tester.tap(likeFinder);
    await tester.pumpAndSettle();

    // after like, the count should increase by 1 somewhere
    expect(find.text('${first.likes + 1}'), findsWidgets);

    // Empty composer submission does not create a blank post
    await tester.tap(find.byKey(const Key('post-compose-submit')));
    await tester.pumpAndSettle();

    // ensure no empty text appears
    expect(find.text(''), findsNothing);
  });
}
