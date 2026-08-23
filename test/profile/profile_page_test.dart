import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:manox/features/profile/data/demo_profile.dart';
import 'package:manox/features/profile/domain/profile_repository.dart';
import 'package:manox/features/profile/presentation/profile_page.dart';
import 'package:manox/core/theme/theme.dart';

class FakeProfileRepository implements ProfileRepository {
  @override
  Future<ProfileData> fetchProfile() async {
    return demoProfile;
  }

  @override
  Future<List<String>> fetchPostIds() async {
    return demoProfile.postIds;
  }
}

void main() {
  testWidgets(
    'ProfilePage renders and shows basic info',
    (WidgetTester tester) async {
      final view = tester.view;

      // Give the profile page enough room to render its complete layout.
      view.devicePixelRatio = 1.0;
      view.physicalSize = const Size(800, 1200);

      addTearDown(() {
        view.resetDevicePixelRatio();
        view.resetPhysicalSize();
      });

      final repository = FakeProfileRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: manoxTheme(),
          home: ProfilePage(
            repository: repository,
          ),
        ),
      );

      // Wait for fetchProfile/fetchPostIds and all resulting rebuilds.
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('profile-avatar')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('profile-name')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('profile-handle')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('profile-bio')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('profile-edit-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('profile-settings-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('profile-post-count')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('profile-followers-count')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('profile-following-count')),
        findsOneWidget,
      );
    },
  );
}
