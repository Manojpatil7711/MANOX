import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/theme.dart';
import 'features/auth/auth.dart';
import 'features/auth/presentation/splash_page.dart';
import 'features/home/presentation/home_page.dart';
import 'features/home/presentation/beats_page.dart';
import 'features/home/presentation/create_post_page.dart';
import 'features/home/presentation/tools_page.dart';
import 'features/home/presentation/live_page.dart';
import 'features/home/presentation/entertainment_page.dart';
import 'features/profile/profile.dart';
import 'features/profile/presentation/public_profile_page.dart';
import 'features/onboarding/onboarding.dart';
import 'features/creator/creator.dart';
import 'features/settings/settings.dart';
import 'features/communication/presentation/communication_pages.dart';
import 'features/editor/presentation/safe_media_editor_page.dart';
import 'services/supabase_service.dart';

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier() { final stream = SupabaseService.authStateChanges(); _subscription = stream?.listen((_) => notifyListeners()); }
  StreamSubscription? _subscription;
  @override void dispose() { _subscription?.cancel(); super.dispose(); }
}

class ManoxApp extends StatelessWidget {
  const ManoxApp({super.key});
  static final _authRefresh = _AuthRefreshNotifier();
  static final GoRouter _router = GoRouter(
    initialLocation: '/splash', refreshListenable: _authRefresh,
    redirect: (context, state) {
      final authenticated = SupabaseService.client?.auth.currentSession != null;
      final path = state.matchedLocation; final authRoute = path.startsWith('/auth');
      if (path == '/splash' || path == '/onboarding') return null;
      if (!authenticated && !authRoute) return '/auth';
      if (authenticated && authRoute) return '/home';
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
      GoRoute(path: '/create', builder: (context, state) => const CreatePostPage()),
      GoRoute(path: '/tools', builder: (context, state) => const ToolsPage()),
      GoRoute(path: '/beats', builder: (context, state) => const BeatsPage()),
      GoRoute(path: '/live', builder: (context, state) => const LivePage()),
      GoRoute(path: '/entertainment', builder: (context, state) => const EntertainmentPage()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
      GoRoute(path: '/profile/:userId', builder: (context, state) => PublicProfilePage(userId: state.pathParameters['userId']!)),
      GoRoute(path: '/creator', builder: (context, state) => const CreatorPage()),
      GoRoute(path: '/monetization', builder: (context, state) => const MonetizationPage()),
      GoRoute(path: '/payout', builder: (context, state) => const PayoutPage()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
      GoRoute(path: '/messages', builder: (context, state) => const MessagesPage()),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsPage()),
      GoRoute(path: '/search', builder: (context, state) => const SearchPage()),
      GoRoute(path: '/editor', builder: (context, state) {
        final raw = state.extra; final extra = raw is Map ? Map<String, dynamic>.from(raw) : const <String, dynamic>{};
        return SafeMediaEditorPage(isVideo: extra['isVideo'] == true, mediaPath: extra['mediaPath'] is String ? extra['mediaPath'] as String : null);
      }),
    ],
  );
  @override Widget build(BuildContext context) => MaterialApp.router(title: 'MANOX', debugShowCheckedModeBanner: false, theme: manoxTheme(), routerConfig: _router);
}
