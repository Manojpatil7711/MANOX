import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:manox/core/theme/theme.dart';
import 'package:manox/features/home/data/demo_posts.dart';
import 'package:manox/features/home/presentation/widgets/post_card.dart';

void main() {
  HomeDemoData buildPost({required bool allowComments, required bool allowDownloads}) {
    return HomeDemoData(
      id: 'permission-test',
      creatorName: 'MANOX Creator',
      handle: '@manox',
      text: 'Permission regression test',
      likes: 10,
      comments: 3,
      imagePath: null,
      likedByMe: false,
      savedByMe: false,
      isRemote: false,
      ownerUserId: null,
      allowComments: allowComments,
      allowDownloads: allowDownloads,
    );
  }

  testWidgets('disabled comments are visibly unavailable', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: manoxTheme(),
        home: Scaffold(
          body: PostCard(
            data: buildPost(allowComments: false, allowDownloads: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final commentButton = find.byType(TextButton).at(1);
    expect(commentButton, findsOneWidget);
    final widget = tester.widget<TextButton>(commentButton);
    expect(widget.onPressed, isNull);
    expect(find.byIcon(Icons.comments_disabled_outlined), findsOneWidget);
  });

  testWidgets('enabled comments remain actionable', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: manoxTheme(),
        home: Scaffold(
          body: PostCard(
            data: buildPost(allowComments: true, allowDownloads: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final commentButton = find.byType(TextButton).at(1);
    expect(commentButton, findsOneWidget);
    final widget = tester.widget<TextButton>(commentButton);
    expect(widget.onPressed, isNotNull);
    expect(find.byIcon(Icons.comment_outlined), findsOneWidget);
  });
}
