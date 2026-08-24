import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/theme.dart';
import 'features/auth/auth.dart';
import 'features/auth/presentation/splash_page.dart';
import 'features/home/presentation/home_page.dart';
import 'features/profile/profile.dart';
import 'features/onboarding/onboarding.dart';
import 'features/creator/creator.dart';
import 'features/settings/settings.dart';
import 'services/supabase_service.dart';

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier() {
    final stream = SupabaseService.authStateChanges();
    _subscription = stream?.listen((_) => notifyListeners());
  }
  StreamSubscription? _subscription;
  @override
  void dispose() { _subscription?.cancel(); super.dispose(); }
}

class ManoxApp extends StatelessWidget {
  const ManoxApp({super.key});
  static final _authRefresh = _AuthRefreshNotifier();
  static final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: _authRefresh,
    redirect: (context, state) {
      final session = SupabaseService.client?.auth.currentSession;
      final isAuthenticated = session != null;
      final path = state.matchedLocation;
      final isAuthRoute = path.startsWith('/auth');
      if (path == '/splash' || path == '/onboarding') return null;
      if (!isAuthenticated && !isAuthRoute) return '/auth';
      if (isAuthenticated && isAuthRoute) return '/home';
      return null;
    },
    routes: <GoRoute>[
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingPage()),
      GoRoute(path: '/auth', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/auth/signup', builder: (context, state) => const SignupPage()),
      GoRoute(path: '/auth/forgot', builder: (context, state) => const ForgotPasswordPage()),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
      GoRoute(path: '/creator', builder: (context, state) => const CreatorPage()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
    ],
  );
  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'MANOX', debugShowCheckedModeBanner: false, theme: manoxTheme(), routerConfig: _router,
  );
}
