import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/theme.dart';
import 'services/supabase_service.dart';

class ManoxApp extends StatefulWidget {
  const ManoxApp({super.key});

  @override
  State<ManoxApp> createState() => _ManoxAppState();
}

class _ManoxAppState extends State<ManoxApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _router = GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) => const ManoxHomePage(),
        ),
        // future routes: /login, /signup, /home, /profile, /creator, etc.
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Text(state.error.toString())),
      ),
    );
  }

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
        title: const Text('MANOX', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.public, size: 72),
            SizedBox(height: 24),
            Text('Welcome to MANOX', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('Create. Connect. Grow.', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
