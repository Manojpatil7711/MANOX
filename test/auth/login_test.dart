import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:manox/features/auth/presentation/login_page.dart';
import 'package:manox/features/auth/domain/auth_repository.dart';

class FakeAuthRepo implements AuthRepository {
  bool shouldFail = false;
  bool delay = false;
  int signInCalls = 0;

  @override
  Future<void> signIn(String email, String password) async {
    signInCalls++;
    if (delay) await Future.delayed(const Duration(milliseconds: 200));
    if (shouldFail) throw AuthException('Invalid email or password.');
  }

  @override
  Future<void> signUp(String email, String password) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> resetPassword(String email) async {}
}

void main() {
  Widget buildTestApp(FakeAuthRepo repo) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => LoginPage(authRepository: repo)),
        GoRoute(path: '/home', builder: (context, state) => const Scaffold(body: Center(child: Text('HOME')))),
      ],
    );

    return MaterialApp.router(routerConfig: router, theme: ThemeData.dark());
  }

  testWidgets('Login page renders and has required fields', (WidgetTester tester) async {
    final repo = FakeAuthRepo();
    await tester.pumpWidget(buildTestApp(repo));

    expect(find.byKey(const Key('login-email')), findsOneWidget);
    expect(find.byKey(const Key('login-password')), findsOneWidget);
    expect(find.byKey(const Key('login-submit')), findsOneWidget);
  });

  testWidgets('Login validation: empty and invalid inputs', (WidgetTester tester) async {
    final repo = FakeAuthRepo();
    await tester.pumpWidget(buildTestApp(repo));

    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('login-email')), 'bad-email');
    await tester.enterText(find.byKey(const Key('login-password')), '123456');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();
    expect(find.text('Enter a valid email'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('login-email')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('login-password')), '123');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
  });

  testWidgets('Login success navigates to /home', (WidgetTester tester) async {
    final repo = FakeAuthRepo();
    await tester.pumpWidget(buildTestApp(repo));

    await tester.enterText(find.byKey(const Key('login-email')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('login-password')), 'password123');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
    expect(repo.signInCalls, 1);
  });

  testWidgets('Login failure shows friendly error and prevents duplicate submissions', (WidgetTester tester) async {
    final repo = FakeAuthRepo()..shouldFail = true..delay = true;
    await tester.pumpWidget(buildTestApp(repo));

    await tester.enterText(find.byKey(const Key('login-email')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('login-password')), 'password123');

    final submit = find.byKey(const Key('login-submit'));
    await tester.tap(submit);
    await tester.pump();

    // The first submission has started, so the button is disabled before the
    // second tap. This verifies the real duplicate-submission guard.
    expect(tester.widget<ElevatedButton>(submit).onPressed, isNull);
    await tester.tap(submit, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-error')), findsOneWidget);
    expect(find.text('Invalid email or password.'), findsOneWidget);
    expect(repo.signInCalls, 1);
  });
}
