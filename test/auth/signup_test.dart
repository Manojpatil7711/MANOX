import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:manox/features/auth/presentation/signup_page.dart';
import 'package:manox/features/auth/domain/auth_repository.dart';

class FakeAuthRepo implements AuthRepository {
  bool shouldFail = false;
  bool delay = false;
  bool authenticated = true;
  int signUpCalls = 0;

  @override
  bool get hasSession => authenticated;
  @override
  Future<void> signUp({required String firstName, required String surname, required String mobile, required String email, required String password}) async {
    signUpCalls++;
    if (delay) await Future.delayed(const Duration(milliseconds: 200));
    if (shouldFail) throw AuthException('Email already registered.');
  }
  @override Future<void> signIn(String email, String password) async {}
  @override Future<void> sendEmailOtp(String email) async {}
  @override Future<void> verifyEmailOtp(String email, String token) async {}
  @override Future<void> signInWithGoogle() async {}
  @override Future<void> signOut() async {}
  @override Future<void> resetPassword(String email) async {}
}

void main() {
  Widget buildTestApp(FakeAuthRepo repo) {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (context, state) => SignupPage(authRepository: repo)),
      GoRoute(path: '/auth', builder: (context, state) => const Scaffold(body: Center(child: Text('AUTH')))),
      GoRoute(path: '/home', builder: (context, state) => const Scaffold(body: Center(child: Text('HOME')))),
    ]);
    return MaterialApp.router(routerConfig: router, theme: ThemeData.dark());
  }

  Future<void> fillValidForm(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).at(0), 'Ava');
    await tester.enterText(find.byType(TextFormField).at(1), 'Carter');
    await tester.enterText(find.byType(TextFormField).at(2), '9876543210');
    await tester.enterText(find.byKey(const Key('signup-email')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('signup-password')), 'Password1!');
    await tester.enterText(find.byKey(const Key('signup-confirm')), 'Password1!');
  }

  Future<void> tapSubmit(WidgetTester tester) async {
    final submit = find.byKey(const Key('signup-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
  }

  testWidgets('Signup renders and fields exist', (WidgetTester tester) async {
    final repo = FakeAuthRepo();
    await tester.pumpWidget(buildTestApp(repo));
    expect(find.byType(TextFormField), findsNWidgets(6));
    expect(find.byKey(const Key('signup-email')), findsOneWidget);
    expect(find.byKey(const Key('signup-password')), findsOneWidget);
    expect(find.byKey(const Key('signup-confirm')), findsOneWidget);
    expect(find.byKey(const Key('signup-submit')), findsOneWidget);
  });

  testWidgets('Signup validation works', (WidgetTester tester) async {
    final repo = FakeAuthRepo();
    await tester.pumpWidget(buildTestApp(repo));
    await tapSubmit(tester);
    await tester.pump();
    expect(find.text('First name is required'), findsOneWidget);
    expect(find.text('Surname is required'), findsOneWidget);
    expect(find.text('Enter a valid mobile number'), findsOneWidget);
    expect(find.text('Email address is required'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Ava');
    await tester.enterText(find.byType(TextFormField).at(1), 'Carter');
    await tester.enterText(find.byType(TextFormField).at(2), '9876543210');
    await tester.enterText(find.byKey(const Key('signup-email')), 'bad-email');
    await tester.enterText(find.byKey(const Key('signup-password')), 'Password1!');
    await tester.enterText(find.byKey(const Key('signup-confirm')), 'Password1!');
    await tapSubmit(tester);
    await tester.pump();
    expect(find.text('Enter a valid email'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('signup-email')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('signup-password')), '123');
    await tester.enterText(find.byKey(const Key('signup-confirm')), '123');
    await tapSubmit(tester);
    await tester.pump();
    expect(find.text('Use at least 8 characters'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('signup-password')), 'Password1!');
    await tester.enterText(find.byKey(const Key('signup-confirm')), 'Password2!');
    await tapSubmit(tester);
    await tester.pump();
    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('Signup success navigates to /home', (WidgetTester tester) async {
    final repo = FakeAuthRepo();
    await tester.pumpWidget(buildTestApp(repo));
    await fillValidForm(tester);
    await tapSubmit(tester);
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
    expect(repo.signUpCalls, 1);
  });

  testWidgets('Signup confirmation screen appears when email confirmation is required', (WidgetTester tester) async {
    final repo = FakeAuthRepo()..authenticated = false;
    await tester.pumpWidget(buildTestApp(repo));
    await fillValidForm(tester);
    await tapSubmit(tester);
    await tester.pumpAndSettle();
    expect(find.text('CHECK YOUR EMAIL'), findsOneWidget);
    expect(find.text('BACK TO SIGN IN'), findsOneWidget);
  });

  testWidgets('Signup failure displays friendly error and prevents duplicate submissions', (WidgetTester tester) async {
    final repo = FakeAuthRepo()..shouldFail = true..delay = true;
    await tester.pumpWidget(buildTestApp(repo));
    await fillValidForm(tester);
    final submit = find.byKey(const Key('signup-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(tester.widget<ElevatedButton>(submit).onPressed, isNull);
    await tester.tap(submit, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('signup-error')), findsOneWidget);
    expect(find.text('Email already registered.'), findsOneWidget);
    expect(repo.signUpCalls, 1);
  });
}
