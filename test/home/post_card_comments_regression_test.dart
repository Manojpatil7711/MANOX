import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manox/core/theme/theme.dart';
import 'package:manox/features/home/data/demo_posts.dart';
import 'package:manox/features/home/data/supabase_post_repository.dart';
import 'package:manox/features/home/presentation/widgets/post_card.dart';

class _CommentsRepository extends SupabasePostRepository {
  _CommentsRepository({this.failSend = false});

  final bool failSend;
  final List<String> sentBodies = <String>[];

  @override
  Future<bool> isOwner(String contentId) async => false;

  @override
  Future<bool> isSaved(String contentId) async => false;

  @override
  Future<List<ManoxComment>> fetchComments(String contentId, {int limit = 50}) async => <ManoxComment>[];

  @override
  Future<void> addComment(String contentId, String body) async {
    if (failSend) throw StateError('test network failure');
    sentBodies.add(body);
  }
}

HomeDemoData _post() => HomeDemoData(
      id: 'comment-regression-post',
      creatorName: 'MANOX Creator',
      handle: '@manox',
      text: 'Comment regression test',
      likes: 0,
      comments: 0,
      imagePath: null,
      likedByMe: false,
      savedByMe: false,
      isRemote: true,
      ownerUserId: 'creator-user-id',
      allowComments: true,
      allowDownloads: true,
    );

Future<void> _openComments(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.comment_outlined));
  await tester.pumpAndSettle();
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('successful comment appears once and clears the composer', (tester) async {
    final repository = _CommentsRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: manoxTheme(),
        home: Scaffold(body: PostCard(data: _post(), repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    await _openComments(tester);
    expect(find.text('No comments yet. Be the first!'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Hello MANOX');
    await tester.tap(find.byTooltip('Send comment'));
    await tester.pumpAndSettle();

    expect(repository.sentBodies, <String>['Hello MANOX']);
    expect(find.text('Hello MANOX'), findsOneWidget);
    expect(find.text('No comments yet. Be the first!'), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, isEmpty);
  });

  testWidgets('failed comment keeps draft and allows retry', (tester) async {
    final repository = _CommentsRepository(failSend: true);
    await tester.pumpWidget(
      MaterialApp(
        theme: manoxTheme(),
        home: Scaffold(body: PostCard(data: _post(), repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    await _openComments(tester);
    await tester.enterText(find.byType(TextField), 'Please keep this draft');
    await tester.tap(find.byTooltip('Send comment'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Please keep this draft',
    );
    expect(find.textContaining('Comment could not be sent:'), findsOneWidget);
    expect(repository.sentBodies, isEmpty);
  });

  testWidgets('comment composer blocks whitespace-only submissions', (tester) async {
    final repository = _CommentsRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: manoxTheme(),
        home: Scaffold(body: PostCard(data: _post(), repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    await _openComments(tester);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byTooltip('Send comment'));
    await tester.pumpAndSettle();

    expect(repository.sentBodies, isEmpty);
    expect(find.text('No comments yet. Be the first!'), findsOneWidget);
  });
}
