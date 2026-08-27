import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/theme.dart';
import 'features/auth/auth.dart';
import 'features/auth/presentation/splash_page.dart';
import 'features/home/presentation/kids_mode_gate_page.dart';
import 'features/home/presentation/kids_home_page.dart';
import 'features/home/presentation/beats_page.dart';
import 'features/home/presentation/create_post_page.dart';
import 'features/home/presentation/tools_page.dart';
import 'features/home/presentation/live_page.dart';
import 'features/home/presentation/entertainment_page.dart';
import 'features/home/presentation/discovery_page.dart';
import 'features/home/presentation/learn_page.dart';
import 'features/profile/profile.dart';
import 'features/profile/presentation/public_profile_page.dart';
import 'features/onboarding/onboarding.dart';
import 'features/creator/creator.dart';
import 'features/settings/settings.dart';
import 'features/settings/presentation/kids_protection_page.dart';
import 'features/communication/presentation/communication_pages.dart';
import 'features/editor/presentation/safe_media_editor_page.dart';
import 'features/editor/presentation/professional_media_editor_page.dart';
import 'features/compliance/presentation/community_safety_page.dart';
import 'features/safety/presentation/safety_alert_button.dart';
import 'features/safety/presentation/women_safety_page.dart';
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
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/', builder: (_, __) => const KidsModeGatePage()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
      GoRoute(path: '/auth', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/auth/signup', builder: (_, __) => const SignupPage()),
      GoRoute(path: '/auth/forgot', builder: (_, __) => const ForgotPasswordPage()),
      GoRoute(path: '/home', builder: (_, __) => const KidsModeGatePage()),
      GoRoute(path: '/kids-home', builder: (_, __) => const KidsHomePage()),
      GoRoute(path: '/kids-protection', builder: (_, __) => const KidsProtectionPage()),
      GoRoute(path: '/create', builder: (_, __) => const CreatePostPage()),
      GoRoute(path: '/tools', builder: (_, __) => const ToolsPage()),
      GoRoute(path: '/beats', builder: (_, __) => const BeatsPage()),
      GoRoute(path: '/live', builder: (_, __) => const LivePage()),
      GoRoute(path: '/entertainment', builder: (_, __) => const EntertainmentPage()),
      GoRoute(path: '/trending', builder: (_, __) => const DiscoveryPage(title: 'Trending', icon: Icons.local_fire_department_rounded)),
      GoRoute(path: '/learn', builder: (_, __) => const LearnPage()),
      GoRoute(path: '/sports', builder: (_, __) => const DiscoveryPage(title: 'Sports', icon: Icons.sports_soccer_rounded)),
      GoRoute(path: '/women-safety', builder: (_, __) => const WomenSafetyPage()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
      GoRoute(path: '/profile/:userId', builder: (context, state) => PublicProfilePage(userId: state.pathParameters['userId']!)),
      GoRoute(path: '/creator', builder: (_, __) => const CreatorPage()),
      GoRoute(path: '/monetization', builder: (_, __) => const MonetizationPage()),
      GoRoute(path: '/payout', builder: (_, __) => const PayoutPage()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
      GoRoute(path: '/community-safety', builder: (_, __) => const CommunitySafetyPage()),
      GoRoute(path: '/messages', builder: (_, __) => const MessagesPage()),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsPage()),
      GoRoute(path: '/search', builder: (_, __) => const SearchPage()),
      GoRoute(path: '/editor', builder: (context, state) { final raw = state.extra; final extra = raw is Map ? Map<String, dynamic>.from(raw) : const <String, dynamic>{}; return ProfessionalMediaEditorPage(isVideo: extra['isVideo'] == true, mediaPath: extra['mediaPath'] is String ? extra['mediaPath'] as String : null); }),
      GoRoute(path: '/editor-safe', builder: (context, state) { final raw = state.extra; final extra = raw is Map ? Map<String, dynamic>.from(raw) : const <String, dynamic>{}; return SafeMediaEditorPage(isVideo: extra['isVideo'] == true, mediaPath: extra['mediaPath'] is String ? extra['mediaPath'] as String : null); }),
    ],
  );
  @override Widget build(BuildContext context) => MaterialApp.router(title: 'MANOX', debugShowCheckedModeBanner: false, theme: manoxTheme(), routerConfig: _router, builder: (context, child) => SafetyAlertOverlay(child: child ?? const SizedBox.shrink()));
}
