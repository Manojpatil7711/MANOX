import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:manox/features/auth/presentation/forgot_password_page.dart';
import 'package:manox/features/auth/domain/auth_repository.dart';

class FakeAuthRepo implements AuthRepository {
  bool shouldFail = false;
  bool delay = false;
  int resetCalls = 0;

  @override
  bool get hasSession => false;

  @override
  Future<void> resetPassword(String email) async {
    resetCalls++;
    if (delay) await Future.delayed(const Duration(milliseconds: 200));
    if (shouldFail) throw AuthException('Failed to send reset');
  }

  @override
  Future<void> signIn(String email, String password) async {}

  @override
  Future<void> signUp({required String firstName, required String surname, required String mobile, required String email, required String password}) async {}

  @override
  Future<void> sendEmailOtp(String email) async {}

  @override
  Future<void> verifyEmailOtp(String email, String token) async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  Widget buildTestApp(FakeAuthRepo repo) {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (context, state) => ForgotPasswordPage(authRepository: repo)),
    ]);
    return MaterialApp.router(routerConfig: router, theme: ThemeData.dark());
  }

  testWidgets('Forgot password renders and validates', (WidgetTester tester) async {
    final repo = FakeAuthRepo();
    await tester.pumpWidget(buildTestApp(repo));
    expect(find.byKey(const Key('forgot-email')), findsOneWidget);
    expect(find.byKey(const Key('forgot-submit')), findsOneWidget);
    await tester.tap(find.byKey(const Key('forgot-submit')));
    await tester.pump();
    expect(find.text('Email is required'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('forgot-email')), 'bad-email');
    await tester.tap(find.byKey(const Key('forgot-submit')));
    await tester.pump();
    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('Forgot password success and failure', (WidgetTester tester) async {
    final repo = FakeAuthRepo();
    await tester.pumpWidget(buildTestApp(repo));
    await tester.enterText(find.byKey(const Key('forgot-email')), 'test@example.com');
    await tester.tap(find.byKey(const Key('forgot-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('forgot-message')), findsOneWidget);
    expect(repo.resetCalls, 1);

    final repo2 = FakeAuthRepo()..shouldFail = true..delay = true;
    await tester.pumpWidget(buildTestApp(repo2));
    await tester.enterText(find.byKey(const Key('forgot-email')), 'test@example.com');
    await tester.tap(find.byKey(const Key('forgot-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('forgot-message')), findsOneWidget);
    expect(repo2.resetCalls, 1);
  });
}
