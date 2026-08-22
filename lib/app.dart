import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/theme.dart';

class ManoxApp extends StatelessWidget {
  const ManoxApp({super.key});

  static final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: <GoRoute>[
      GoRoute(
        path: '/',
        name: 'root',
        builder: (context, state) => const ManoxHomePage(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const ManoxHomePage(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/creator',
        name: 'creator',
        builder: (context, state) => const CreatorPage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MANOX',
      debugShowCheckedModeBanner: false,
      theme: manoxTheme(),
      routerConfig: _router,
    );
  }
}

class ManoxHomePage extends StatelessWidget {
  const ManoxHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MANOX',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.public,
              key: Key('manox-home-logo'), // preserved stable key for tests
              size: 72,
            ),
            SizedBox(height: 24),
            Text(
              'Welcome to MANOX',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Create. Connect. Grow.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Onboarding')));
}

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Auth')));
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Profile')));
}

class CreatorPage extends StatelessWidget {
  const CreatorPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Creator')));
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Settings')));
}
