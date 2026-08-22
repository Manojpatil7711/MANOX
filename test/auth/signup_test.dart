import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:manox/features/auth/presentation/signup_page.dart';
import 'package:manox/features/auth/domain/auth_repository.dart';

class FakeAuthRepo implements AuthRepository {
  bool shouldFail = false;
  bool delay = false;
  int signUpCalls = 0;

  @override
  Future<void> signUp(String email, String password) async {
    signUpCalls++;
    if (delay) await Future.delayed(const Duration(milliseconds: 200));
    if (shouldFail) throw AuthException('Email already registered.');
  }

  @override
  Future<void> signIn(String email, String password) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> resetPassword(String email) async {}
}

void main() {
  Widget buildTestApp(FakeAuthRepo repo) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => SignupPage(authRepository: repo)),
        GoRoute(path: '/home', builder: (context, state) => const Scaffold(body: Center(child: Text('HOME')))),
      ],
    );

    return MaterialApp.router(routerConfig: router, theme: ThemeData.dark());
  }

  testWidgets('Signup renders and fields exist', (WidgetTester tester) async {
    final repo = FakeAuthRepo();
    await tester.pumpWidget(buildTestApp(repo));

    expect(find.byKey(const Key('signup-email')), findsOneWidget);
    expect(find.byKey(const Key('signup-password')), findsOneWidget);
    expect(find.byKey(const Key('signup-confirm')), findsOneWidget);
    expect(find.byKey(const Key('signup-submit')), findsOneWidget);
  });

  testWidgets('Signup validation works', (WidgetTester tester) async {
    final repo = FakeAuthRepo();
    await tester.pumpWidget(buildTestApp(repo));

    await tester.tap(find.byKey(const Key('signup-submit')));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('signup-email')), 'bad-email');
    await tester.enterText(find.byKey(const Key('signup-password')), '123456');
    await tester.enterText(find.byKey(const Key('signup-confirm')), '123456');
    await tester.tap(find.byKey(const Key('signup-submit')));
    await tester.pump();
    expect(find.text('Enter a valid email'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('signup-email')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('signup-password')), '123');
    await tester.enterText(find.byKey(const Key('signup-confirm')), '123');
    await tester.tap(find.byKey(const Key('signup-submit')));
    await tester.pump();
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('signup-password')), 'password1');
    await tester.enterText(find.byKey(const Key('signup-confirm')), 'password2');
    await tester.tap(find.byKey(const Key('signup-submit')));
    await tester.pump();
    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('Signup success navigates to /home', (WidgetTester tester) async {
    final repo = FakeAuthRepo();
    await tester.pumpWidget(buildTestApp(repo));

    await tester.enterText(find.byKey(const Key('signup-email')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('signup-password')), 'password123');
    await tester.enterText(find.byKey(const Key('signup-confirm')), 'password123');
    await tester.tap(find.byKey(const Key('signup-submit')));
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
    expect(repo.signUpCalls, 1);
  });

  testWidgets('Signup failure displays friendly error and prevents duplicate submissions', (WidgetTester tester) async {
    final repo = FakeAuthRepo();
    repo.shouldFail = true;
    repo.delay = true;
    await tester.pumpWidget(buildTestApp(repo));

    await tester.enterText(find.byKey(const Key('signup-email')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('signup-password')), 'password123');
    await tester.enterText(find.byKey(const Key('signup-confirm')), 'password123');

    await tester.tap(find.byKey(const Key('signup-submit')));
    await tester.tap(find.byKey(const Key('signup-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('signup-error')), findsOneWidget);
    expect(repo.signUpCalls, 1);
  });
}
